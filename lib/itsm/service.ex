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
  alias Itsm.Comments.Comment
  alias Itsm.Comments
  alias Itsm.Attachments
  alias Itsm.Team.Member
  alias Itsm.Approvals
  alias Itsm.Requests
  alias Itsm.Util

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

  # ✅ 어떤 구조체(resource)가 들어오든 다 처리하는 범용 함수
  def list_comments(resource) do
    Comment
    # "Request"
    |> where([c], c.resource_type == ^Util.resource_name(resource))
    # ID 매칭
    |> where([c], c.resource_id == ^resource.id)
    |> order_by([c], asc: c.inserted_at)
    # 첨부파일/작성자 로딩
    |> preload([:user, :attachments])
    |> Repo.all()
  end

  def create_request(
        %User{} = user,
        %Category{} = category,
        %User{} = assignee,
        handle_attachments,
        attrs \\ %{}
      ) do
    Multi.new()
    |> Multi.insert(:request, Requests.change_request(user, category, assignee, attrs))
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Approvals.create_approval(repo, request, user)
    end)
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(repo, request, handle_attachments)
    end)
    |> Repo.transaction()
    |> broadcast_result(:request_created)
  end

  def create_comment(resource, %User{} = user, handle_attachments, attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:comment, Comments.changeset_comment(resource, user, attrs))
    |> Multi.run(:attachments, fn repo, %{comment: comment} ->
      Attachments.create_attachments(repo, comment, handle_attachments)
    end)
    |> Repo.transaction()
    |> Comments.broadcast_result(resource.id)
  end

  # ✅ 결과 브로드캐스트 헬퍼
  defp broadcast_result({:ok, %{request: request}} = _result, _event) do
    request = Repo.preload(request, [:category, :attachments])
    Approvals.broadcast_approvals_list({:request_created, request})
    {:ok, request}
  end

  defp broadcast_result(error, _), do: error

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

      with {:ok, approval} <- Approvals.create_approval(approval_attrs),
           {:ok, request} <- transition_to_next_status(request, action) do
        Approvals.broadcast_approvals_list({:request_updated, request})
        {request, approval}
      else
        {:error, _} = error -> Repo.rollback(error)
      end
    end)
  end

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
