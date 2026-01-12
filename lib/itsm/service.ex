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
  alias Itsm.Requests

  # alias Itsm.Team.Crew
  alias Itsm.Team.Member

  # ✅ 특정 request의 변경사항 구독
  def subscribe_request(request_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "request:#{request_id}")
  end

  def broadcast_request(request_id, message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "request:#{request_id}", message)
  end

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

  @doc """
  Returns the list of requests.

  ## Examples

      iex> list_requests()
      [%Request{}, ...]

  """
  def list_requests do
    Repo.all(Request)
    |> Repo.preload(:category)
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

  @doc """
  Gets a single request.

  Raises `Ecto.NoResultsError` if the Request does not exist.

  ## Examples

      iex> get_request!(123)
      %Request{}

      iex> get_request!(456)
      ** (Ecto.NoResultsError)

  """

  def get_request!(id) do
    Request
    |> Repo.get!(id)
    |> Repo.preload([:category, :attachments])
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
  def create_request(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:requests)
    |> Request.changeset(attrs)
    |> Ecto.Changeset.put_change(:requestor_name, user.display_name)
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        broadcast_approvals_list({:request_created, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def create_full_request(
        %User{} = user,
        %Category{} = category,
        %User{} = assignee,
        attrs \\ %{}
      ) do
    Multi.new()
    |> Multi.insert(:request, Requests.change_request(user, category, assignee, attrs))
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Itsm.Approvals.create_approval(repo, request, user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{request: request, approval: _approval}} ->
        request = Repo.preload(request, :category)
        broadcast_approvals_list({:request_created, request})
        {:ok, request}

      {:error, _failed_operation, _failed_value, _changes_so_far} = error ->
        error
    end
  end

  @doc """
  Updates a request.

  ## Examples

      iex> update_request(request, %{field: new_value})
      {:ok, %Request{}}

      iex> update_request(request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_request(current_user, %Request{requestor_id: requestor_id} = request, attrs)
      when current_user.id == requestor_id do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        broadcast_request(request.id, {:request_updated, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Deletes a request.

  ## Examples

      iex> delete_request(request)
      {:ok, %Request{}}

      iex> delete_request(request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking request changes.

  ## Examples

      iex> change_request(request)
      %Ecto.Changeset{data: %Request{}}

  """
  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(request, attrs)
  end

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

  # 승인 처리
  # def approve_request(request, approver) do
  #   # next_status = get_next_status(request.status)

  #   Repo.transaction(fn ->
  #     # 1. 현재 상태를 히스토리에 기록
  #     approval_attrs = %{
  #       request_id: request.id,
  #       # 현재 상태 저장
  #       status: request.status,
  #       action: :approve,
  #       approver_id: approver.employee_number,
  #       approver_name: approver.display_name,
  #       comment: "",
  #       approved_at: DateTime.utc_now()
  #     }

  #     case create_approval(approval_attrs) do
  #       {:ok, approval} ->
  #         # 2. Request 상태를 다음 단계로 업데이트
  #         # case update_request_status(request, next_status) do
  #         case transition_to_next_status(request) do
  #           {:ok, updated_request} ->
  #             {updated_request, approval}

  #           {:error, changeset} ->
  #             IO.inspect(changeset, label: "❌ Changeset Error")
  #             Repo.rollback(changeset)
  #         end

  #       {:error, changeset} ->
  #         IO.inspect(changeset, label: "❌ Approval Creation Error")
  #         Repo.rollback(changeset)
  #     end
  #   end)
  # end

  # # Private 헬퍼 함수들

  # defp update_request_status(request, new_status) do
  #   request
  #   |> Request.changeset(%{status: new_status})
  #   |> Repo.update()
  # end

  # # 상태별 전환 로직 (각 단계마다 다른 처리)
  # defp transition_to_next_status(%Request{status: :request} = request) do
  #   # request → check: 단순 상태 변경
  #   update_request_status(request, :check)
  # end

  # defp transition_to_next_status(%Request{status: :check, category_id: category_id} = request) do
  #   # check → assign: assignee_crew 설정, assignee_id/name 초기화
  #   category = Repo.get!(Category, category_id)

  #   request
  #   |> Request.changeset(%{
  #     status: :plan,
  #     assignee_crew: category.assignee_crew,
  #     assignee_id: nil,
  #     assignee_name: nil
  #   })
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :plan, category_id: category_id} = request) do
  #   # check → assign: assignee_crew 설정, assignee_id/name 초기화
  #   category = Repo.get!(Category, category_id)

  #   request
  #   |> Request.changeset(%{
  #     status: :review,
  #     assignee_crew: category.assignee_crew,
  #     assignee_id: nil,
  #     assignee_name: nil
  #   })
  #   |> Repo.update()
  # end

  # ============================================================================
  # 승인 처리
  # ============================================================================

  @doc """
  결재 요청을 승인 처리합니다.
  각 단계별로 다른 로직을 실행하며, 승인 내역을 기록합니다.

  승인 규칙:
  - plan: Crew member 아무나 가능
  - review: Crew member 중 plan 승인자 제외 (제3자만)
  - start: Crew member 아무나 가능
  - finish: Crew member 아무나 가능
  - verify: Requestor만 가능
  """

  # def approve_request(request, approver) do
  #   # 권한 확인
  #   with {:ok, :authorized} <- can_approve?(request, approver) do
  #     Repo.transaction(fn ->
  #       # 1. 결재 기록 생성
  #       approval_attrs = %{
  #         request_id: request.id,
  #         status: request.status,
  #         action: :approve,
  #         approver_id: approver.id,
  #         approver_name: approver.display_name
  #         # approved_at: DateTime.utc_now()
  #       }

  #       case create_approval(approval_attrs) do
  #         {:ok, approval} ->
  #           # 2. Request 상태를 다음 단계로 업데이트
  #           case transition_to_next_status(request) do
  #             {:ok, updated_request} ->
  #               broadcast_approvals_list({:request_updated, updated_request})
  #               {updated_request, approval}

  #             {:error, changeset} ->
  #               IO.inspect(changeset, label: "❌ Changeset Error")
  #               Repo.rollback(changeset)
  #           end

  #         {:error, changeset} ->
  #           IO.inspect(changeset, label: "❌ Approval Creation Error")
  #           Repo.rollback(changeset)
  #       end
  #     end)
  #   else
  #     {:error, reason} -> {:error, reason}
  #   end
  # end

  # def approve_or_reject_request(request, approver, action) when action in [:approve, :reject] do
  #   with {:ok, :authorized} <- can_approve?(request, approver) do
  #     Repo.transaction(fn ->
  #       approval_attrs = %{
  #         request_id: request.id,
  #         status: request.status,
  #         action: action,
  #         approver_id: approver.id,
  #         approver_name: approver.display_name
  #       }

  #       with {:ok, approval} <- create_approval(approval_attrs),
  #            {:ok, updated_request} <- transition_to_next_status(request) do
  #         broadcast_approvals_list({:request_updated, updated_request})
  #         {updated_request, approval}
  #       else
  #         {:error, _} = error -> Repo.rollback(error)
  #       end
  #     end)
  #   else
  #     {:error, _} = error -> error
  #   end
  # end

  # # ============================================================================
  # # 권한 검증
  # # ============================================================================

  # @doc """
  # 사용자가 해당 단계에서 승인할 권한이 있는지 확인합니다.
  # """
  # defp can_approve?(request, approver) do
  #   case request.status do
  #     :request -> {:ok, :authorized}
  #     # ✅ 개인 단위
  #     :check -> can_approve_check_stage?(request, approver)
  #     # ✅ 팀 단위
  #     :plan -> can_approve_plan_stage?(request, approver)
  #     # ✅ 팀 단위 (plan 승인자 제외)
  #     :review -> can_approve_review_stage?(request, approver)
  #     # ✅ 팀 단위
  #     :start -> can_approve_start_stage?(request, approver)
  #     # ✅ 팀 단위
  #     :finish -> can_approve_finish_stage?(request, approver)
  #     # ✅ Requestor만
  #     :verify -> can_approve_verify_stage?(request, approver)
  #   end
  # end

  # # check 단계: 할당된 개인만 가능
  # defp can_approve_check_stage?(request, approver) do
  #   if request.assignee_id == approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error, "Only #{request.assignee_name} can approve at check stage"}
  #   end
  # end

  # # plan 단계: Crew member 아무나 가능
  # defp can_approve_plan_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # # review 단계: Crew member 중 plan 승인자 제외
  # defp can_approve_review_stage?(request, approver) do
  #   with {:ok, :authorized} <- is_crew_member?(request, approver),
  #        {:ok, :authorized} <- is_not_plan_approver?(request, approver) do
  #     {:ok, :authorized}
  #   else
  #     error -> error
  #   end
  # end

  # # start 단계: Crew member 아무나 가능
  # defp can_approve_start_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # # finish 단계: Crew member 아무나 가능
  # defp can_approve_finish_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # # verify 단계: Requestor만 가능
  # defp can_approve_verify_stage?(request, approver) do
  #   if request.requestor_id == approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error, "Only requestor can verify"}
  #   end
  # end

  # # ============================================================================
  # # 권한 검증 헬퍼
  # # ============================================================================

  # @doc """
  # 사용자가 특정 crew의 member인지 확인합니다.
  # """
  # defp is_crew_member?(request, approver) do
  #   is_member =
  #     from(m in Member,
  #       join: c in Crew,
  #       on: m.crew_id == c.id,
  #       where: m.user_id == ^approver.id,
  #       where: c.name == ^request.assignee_crew,
  #       select: 1,
  #       limit: 1
  #     )
  #     |> Repo.one()

  #   if is_member do
  #     {:ok, :authorized}
  #   else
  #     {:error, "User is not a member of #{request.assignee_crew}"}
  #   end
  # end

  # @doc """
  # 사용자가 해당 request의 plan 단계를 승인한 사람이 아닌지 확인합니다.
  # review 단계에서 plan 승인자는 제외됩니다.
  # """
  # defp is_not_plan_approver?(request, approver) do
  #   plan_approver =
  #     from(a in Approval,
  #       where: a.request_id == ^request.id,
  #       where: a.status == :plan,
  #       where: a.action == :approve,
  #       select: a.approver_id,
  #       order_by: [desc: a.inserted_at],
  #       limit: 1
  #     )
  #     |> Repo.one()

  #   if plan_approver == nil or plan_approver != approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error,
  #      "You (#{approver.display_name}) already approved at plan stage. Third-party review is required."}
  #   end
  # end

  # # ============================================================================
  # # 상태별 전환 로직
  # # ============================================================================

  # # request → check: 단순 상태 변경, 하지만 필요없음. Request 등록시 자동으로 check 상태가 됨
  # # defp transition_to_next_status(%Request{status: :request} = request) do
  # #   update_request_status(request, :check)
  # # end

  # defp transition_to_next_status(%Request{status: :check} = request) do
  #   # check → plan: assignee_id/name 초기화 (팀 단위로 변경)
  #   request
  #   |> Request.changeset(%{
  #     status: :plan,
  #     assignee_id: nil,
  #     assignee_name: nil
  #     # assignee_crew_id는 유지!
  #   })
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :plan} = request) do
  #   # plan → review: 상태만 변경
  #   request
  #   |> Request.changeset(%{status: :review})
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :review} = request) do
  #   # review → start: 상태만 변경
  #   request
  #   |> Request.changeset(%{status: :start})
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :start} = request) do
  #   # start → finish: 상태만 변경
  #   request
  #   |> Request.changeset(%{status: :finish})
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :finish} = request) do
  #   # finish → verify: requestor 할당
  #   request
  #   |> Request.changeset(%{
  #     status: :verify,
  #     assignee_id: request.requestor_id,
  #     assignee_name: request.requestor_name
  #   })
  #   |> Repo.update()
  # end

  # defp transition_to_next_status(%Request{status: :verify} = request) do
  #   # verify → closed: 최종 완료
  #   request
  #   |> Request.changeset(%{status: :closed})
  #   |> Repo.update()
  # end

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
  # 권한 검증
  # ============================================================================

  # defp can_approve?(request, approver) do
  #   case request.status do
  #     :request -> {:ok, :authorized}
  #     :check -> can_approve_check_stage?(request, approver)
  #     :plan -> can_approve_plan_stage?(request, approver)
  #     :review -> can_approve_review_stage?(request, approver)
  #     :start -> can_approve_start_stage?(request, approver)
  #     :finish -> can_approve_finish_stage?(request, approver)
  #     :verify -> can_approve_verify_stage?(request, approver)
  #   end
  # end

  # # reject는 모든 단계에서 가능 (권한 검증 동일)
  # defp can_reject?(request, approver) do
  #   can_approve?(request, approver)
  # end

  # defp can_approve_check_stage?(request, approver) do
  #   if request.assignee_id == approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error, "Only #{request.assignee_name} can approve at check stage"}
  #   end
  # end

  # defp can_approve_plan_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # defp can_approve_review_stage?(request, approver) do
  #   with {:ok, :authorized} <- is_crew_member?(request, approver),
  #        {:ok, :authorized} <- is_not_plan_approver?(request, approver) do
  #     {:ok, :authorized}
  #   else
  #     error -> error
  #   end
  # end

  # defp can_approve_start_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # defp can_approve_finish_stage?(request, approver) do
  #   is_crew_member?(request, approver)
  # end

  # defp can_approve_verify_stage?(request, approver) do
  #   if request.requestor_id == approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error, "Only requestor can verify"}
  #   end
  # end

  # ============================================================================
  # 권한 검증 헬퍼
  # ============================================================================

  # defp is_crew_member?(request, approver) do
  #   is_member =
  #     from(m in Member,
  #       where: m.user_id == ^approver.id,
  #       # ✅ assignee_crew_id 사용
  #       where: m.crew_id == ^request.assignee_crew_id,
  #       select: 1,
  #       limit: 1
  #     )
  #     |> Repo.one()

  #   if is_member do
  #     {:ok, :authorized}
  #   else
  #     {:error, "User is not a member of the assigned crew"}
  #   end
  # end

  # defp is_not_plan_approver?(request, approver) do
  #   plan_approver =
  #     from(a in Approval,
  #       where: a.request_id == ^request.id,
  #       where: a.status == :plan,
  #       where: a.action == :approve,
  #       select: a.approver_id,
  #       order_by: [desc: a.inserted_at],
  #       limit: 1
  #     )
  #     |> Repo.one()

  #   if plan_approver == nil or plan_approver != approver.id do
  #     {:ok, :authorized}
  #   else
  #     {:error,
  #      "You (#{approver.display_name}) already approved at plan stage. Third-party review is required."}
  #   end
  # end

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
