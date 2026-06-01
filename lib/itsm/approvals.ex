defmodule Itsm.Approvals do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Service.Approval
  alias Itsm.Service.Request
  alias Itsm.Crews.CrewsUsers
  alias Itsm.Workflow
  alias Itsm.Finalization

  # ==================================================
  # 조회
  # ==================================================

  def list_approvals_by_request(request_id) do
    Approval
    |> where([a], a.request_id == ^request_id)
    |> order_by([a], asc: :inserted_at)
    |> Repo.all()
  end

  def list_pending_requests(%User{} = current_user) do
    my_crew_ids =
      from(m in CrewsUsers, where: m.user_id == ^current_user.id, select: m.crew_id)
      |> Repo.all()

    requests_i_assigned =
      from(a in Approval,
        where: a.approver_id == ^current_user.id,
        where: a.status == :assignment,
        select: a.request_id
      )
      |> Repo.all()

    Request
    |> where([r], r.status not in [:closed, :rejected])
    |> where(
      [r],
      (r.status == :validation and
         r.requestor_crew_id in ^my_crew_ids and
         r.requestor_id != ^current_user.id) or
        (r.status in [:assignment, :start, :finish] and
           r.assignee_crew_id in ^my_crew_ids) or
        (r.status == :check and
           r.assignee_crew_id in ^my_crew_ids and
           r.id not in ^requests_i_assigned) or
        (r.status == :confirmation and
           r.requestor_id == ^current_user.id)
    )
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:category, :assignee_crew, :requestor_crew])
  end

  # ==================================================
  # 승인 / 반려
  # ==================================================

  def approve(%Request{} = request, %User{} = approver) do
    process_approval(request, approver, :approve)
  end

  def reject(%Request{} = request, %User{} = approver) do
    process_approval(request, approver, :reject)
  end

  defp process_approval(%Request{} = request, %User{} = approver, action)
       when action in [:approve, :reject] do
    result =
      Repo.transaction(fn ->
        with {:ok, changeset} <- Workflow.transition(:service_request, request, action),
             {:ok, updated_request} <- Repo.update(changeset),
             {:ok, approval} <-
               create_approval(approver, %{
                 request_id: request.id,
                 status: request.status,
                 action: action,
                 approver_id: approver.id,
                 approver_name: approver.display_name
               }) do
          preloaded_request =
            Repo.preload(updated_request, [
              :category,
              :attachments,
              requestor_crew: [:users],
              assignee_crew: [:users]
            ])

          {preloaded_request, approval}
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)

    # 트랜잭션 커밋 후 broadcast
    case result do
      {:ok, {preloaded_request, _approval}} ->
        # TODO : Sync 호출 (자산 한번에 10개 이상 신청 대응)
        # 상태가 :finish(또는 워크플로우에 맞는 완료 상태)일 때 바로 실행
        if preloaded_request.status == :confirmation do
          Finalization.execute_after_finish(approver, preloaded_request)
        end

        Itsm.PubSub.Helper.broadcast(__MODULE__, {approver, :request_updated, preloaded_request})

        result

      error ->
        error
    end
  end

  # ==================================================
  # CUD
  # ==================================================

  def create_approval(%User{} = action_user, attrs) do
    %Approval{}
    |> Approval.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, approval} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_approval, approval})
        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_approval(%User{} = action_user, %Request{} = request, repo \\ Repo, opts \\ []) do
    %Approval{
      approver: action_user,
      approver_name: action_user.display_name,
      request: request,
      status: request.status
    }
    |> repo.insert()
    |> case do
      {:ok, approval} ->
        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_approval, approval})
        end

        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_approval_by_request(%Request{id: id}) do
    Approval
    |> where([a], a.request_id == ^id)
    |> Repo.one()
  end
end
