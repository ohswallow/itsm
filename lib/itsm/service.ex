defmodule Itsm.Service do
  @moduledoc """
  The Service context.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Itsm.Repo
  alias Itsm.Service.Category
  alias Itsm.Service.Approval
  alias Itsm.Service.Request
  alias Itsm.Delegations.Delegation
  alias Itsm.Accounts.User
  alias Itsm.Attachments.Attachment
  alias Itsm.Team.Member

  # ✅ 모든 request 리스트 변경사항 구독 (생성, 업데이트 등)
  def subscribe_approvals_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "approvals_list")
  end

  def broadcast_approvals_list(message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "approvals_list", message)
  end

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  def filter_categories(filter) do
    Category
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> sort(filter["sort_by"])
    |> Repo.all()
  end

  defp with_type(query, group) when group in ~w(K_리전_공동존 K_리전_은행존 P_리전 배치자동화) do
    where(query, group: ^group)
  end

  defp with_type(query, _), do: query

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword) do
    where(query, [c], ilike(c.name, ^"%#{keyword}%"))
  end

  defp sort(query, "name") do
    order_by(query, :name)
  end

  defp sort(query, "description_desc") do
    order_by(query, desc: :description)
  end

  defp sort(query, "description_asc") do
    order_by(query, asc: :description)
  end

  defp sort(query, _) do
    order_by(query, :id)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  def list_assignee_requests(current_user) do
    today = Date.utc_today()

    # 1. [내 정보] 내가 속한 Crew ID 목록
    my_crew_ids =
      from(m in Member,
        where: m.user_id == ^current_user.id,
        select: m.crew_id
      )
      |> Repo.all()

    # 2. [위임 정보] 내가 대결자(Delegatee)로서 처리해야 할 위임자들(Delegators)
    # (휴가간 팀장님 업무를 내가 대신 처리)
    delegator_ids =
      from(d in Delegation,
        where: d.delegatee_id == ^current_user.id,
        where: d.start_date <= ^today,
        where: d.end_date >= ^today,
        select: d.delegator_id
      )
      |> Repo.all()

    # 3. [제약 조건 데이터] 내가 'Plan' 단계를 승인했던 Request ID 목록
    # (Review 단계에서 나를 제외하기 위함)
    requests_i_planned =
      from(a in Approval,
        where: a.approver_id == ^current_user.id,
        where: a.status == :plan,
        select: a.request_id
      )
      |> Repo.all()

    # 4. [메인 쿼리]
    Request
    |> where([r], r.status != :closed)
    |> where(
      [r],
      # -----------------------------------------------------------
      # 1. Verify 단계: 요청자(Requestor) 영역
      # -----------------------------------------------------------
      # -----------------------------------------------------------
      # 2. Check 단계: 담당자(Assignee) 개인 영역
      # -> Crew 전체가 아니라, 지정된 Assignee만 볼 수 있음
      # -----------------------------------------------------------
      # -----------------------------------------------------------
      # 3. Plan, Start, Finish 단계: Crew 공용 영역
      # -> Assignee Crew에 속한 사람 누구나 가능
      # -----------------------------------------------------------
      # -----------------------------------------------------------
      # 4. Review 단계: Crew 공용 영역 (단, Plan 수행자 제외)
      # -> Crew 멤버여야 하며, 동시에 Plan을 수행한 기록이 없어야 함
      # -----------------------------------------------------------
      # -----------------------------------------------------------
      # 5. Request (초기) 단계
      # -> 담당자가 지정되었다면 담당자, 아니면 Crew 전체에게 노출
      # -----------------------------------------------------------
      (r.status == :verify and
         (r.requestor_id == ^current_user.id or
            r.requestor_id in ^delegator_ids)) or
        (r.status == :check and
           (r.assignee_id == ^current_user.id or
              r.assignee_id in ^delegator_ids)) or
        (r.status in [:plan, :start, :finish] and
           r.assignee_crew_id in ^my_crew_ids) or
        (r.status == :review and
           r.assignee_crew_id in ^my_crew_ids and
           r.id not in ^requests_i_planned) or
        (r.status == :request and
           (r.assignee_id == ^current_user.id or
              r.assignee_crew_id in ^my_crew_ids))
    )
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:category, :assignee_crew])
  end

  def list_comments(request) do
    request
    |> Ecto.assoc(:comments)
    |> preload(:user)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Creates a request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(
        %User{} = user,
        %Category{} = category,
        %User{} = assignee,
        attrs \\ %{},
        attachments \\ []
      ) do
    # 1. 구조체 명시적 초기화
    new_request = %Request{
      requestor: user,
      requestor_name: user.display_name,
      category: category,
      assignee: assignee,
      assignee_id: assignee.id,
      assignee_name: assignee.display_name
      # requestor_crew_id는 폼(attrs)에서 넘어옴
    }

    Multi.new()
    # 2. Request 생성 (Requests.change_request 대신 직접 changeset 호출)
    |> Multi.insert(:request, Request.changeset(new_request, attrs))
    # 3. 첨부파일 처리 (패턴 매칭 사용)
    |> maybe_insert_attachments(attachments)
    # 4. 결재선 생성
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Itsm.Approvals.create_approval(repo, request, user)
    end)
    |> Repo.transaction()
    |> broadcast_result(:request_created)
  end

  # ✅ 첨부파일 처리: 빈 리스트일 경우 (Multi 그대로 반환)
  defp maybe_insert_attachments(multi, []), do: multi

  # ✅ 첨부파일 처리: 파일이 있을 경우
  defp maybe_insert_attachments(multi, attachments) do
    Multi.run(multi, :attachments, fn repo, %{request: request} ->
      insert_attachments(repo, request, attachments)
    end)
  end

  # ✅ 실제 DB Insert 로직
  defp insert_attachments(repo, request, attachments) do
    results =
      Enum.map(attachments, fn attachment_attrs ->
        %Attachment{request: request}
        |> Attachment.changeset(attachment_attrs)
        |> repo.insert()
      end)

    # 전체 성공 여부 확인
    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, results}
    else
      {:error, :attachment_save_failed}
    end
  end

  # ✅ 결과 브로드캐스트 헬퍼
  defp broadcast_result({:ok, %{request: request}} = _result, event) do
    request = Repo.preload(request, [:category, :attachments])

    case event do
      :request_created -> broadcast_approvals_list({event, request})
    end

    {:ok, request}
  end

  defp broadcast_result(error, _), do: error

  @doc """
  Returns the list of approvals.

  ## Examples

      iex> list_approvals()
      [%Approval{}, ...]

  """
  def list_approvals do
    Repo.all(Approval)
  end

  @doc """
  Gets a single approval.

  Raises `Ecto.NoResultsError` if the Approval does not exist.

  ## Examples

      iex> get_approval!(123)
      %Approval{}

      iex> get_approval!(456)
      ** (Ecto.NoResultsError)

  """
  def get_approval!(id), do: Repo.get!(Approval, id)

  @doc """
  Creates a approval.

  ## Examples

      iex> create_approval(%{field: value})
      {:ok, %Approval{}}

      iex> create_approval(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_approval(attrs \\ %{}) do
    %Approval{}
    |> Approval.changeset(attrs)
    |> Repo.insert()
  end

  # def create_approval(request, attrs \\ %{}) do
  #   attrs = Map.put(attrs, :request_id, request.id)

  #   %Approval{}
  #   |> Approval.changeset(attrs)
  #   |> Repo.insert()
  # end

  @doc """
  Updates a approval.

  ## Examples

      iex> update_approval(approval, %{field: new_value})
      {:ok, %Approval{}}

      iex> update_approval(approval, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_approval(%Approval{} = approval, attrs) do
    approval
    |> Approval.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a approval.

  ## Examples

      iex> delete_approval(approval)
      {:ok, %Approval{}}

      iex> delete_approval(approval)
      {:error, %Ecto.Changeset{}}

  """
  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking approval changes.

  ## Examples

      iex> change_approval(approval)
      %Ecto.Changeset{data: %Approval{}}

  """
  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
  end

  def approve_request(request, approver) do
    process_request(request, approver, :approve)
  end

  def reject_request(request, approver) do
    process_request(request, approver, :reject)
  end

  defp process_request(request, approver, action) do
    Repo.transaction(fn ->
      approval_attrs = %{
        request_id: request.id,
        status: request.status,
        action: action,
        approver_id: approver.id,
        approver_name: approver.display_name
      }

      with {:ok, approval} <- create_approval(approval_attrs),
           {:ok, request} <- transition_to_next_status(request, action) do
        broadcast_approvals_list({:request_updated, request})
        {request, approval}
      else
        {:error, _} = error -> Repo.rollback(error)
      end
    end)
  end

  # ============================================================================
  # 상태별 전환 로직
  # ============================================================================

  defp transition_to_next_status(request, :reject) do
    # reject는 즉시 closed
    request
    |> Request.changeset(%{status: :closed})
    |> Repo.update()
  end

  defp transition_to_next_status(request, :approve) do
    case request.status do
      :check ->
        request
        |> Request.changeset(%{
          status: :plan,
          assignee_id: nil,
          assignee_name: nil
        })
        |> Repo.update()

      :plan ->
        request
        |> Request.changeset(%{status: :review})
        |> Repo.update()

      :review ->
        request
        |> Request.changeset(%{status: :start})
        |> Repo.update()

      :start ->
        request
        |> Request.changeset(%{status: :finish})
        |> Repo.update()

      :finish ->
        request
        |> Request.changeset(%{
          status: :verify,
          assignee_id: request.requestor_id,
          assignee_name: request.requestor_name
        })
        |> Repo.update()

      :verify ->
        request
        |> Request.changeset(%{status: :closed, assignee_id: nil, assignee_name: nil})
        |> Repo.update()
    end
  end
end
