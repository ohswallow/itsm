defmodule Itsm.Approvals do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Comments
  alias Itsm.Service.Approval
  alias Itsm.Service.Request
  alias Itsm.Requests
  alias Itsm.Crews
  alias Itsm.Workflow
  alias Itsm.Finalization
  alias Ecto.Multi

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
    my_crew_ids = Crews.list_my_crews_ids(current_user)
    assigned_request_ids = list_assigned_request_ids(current_user)

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
           r.id not in ^assigned_request_ids) or
        (r.status == :confirmation and
           r.requestor_id == ^current_user.id)
    )
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:category, :assignee_crew, :requestor_crew])
  end

  @doc """
  현재 사용자가 담당자(접수자)로 할당된 요청 ID 목록을 조회합니다.
  """
  def list_assigned_request_ids(%User{} = user) do
    Approval
    |> where([a], a.approver_id == ^user.id and a.status == :assignment)
    |> select([a], a.request_id)
    |> Repo.all()
  end

  def change_approval(%Request{} = request, %User{} = approver, action) do
    Approval.changeset(
      %Approval{},
      %{
        request_id: request.id,
        status: request.status,
        action: action,
        approver_id: approver.id,
        approver_name: approver.display_name
      }
    )
  end

  @spec approve(%Request{}, %User{}, comment: map() | nil) :: tuple()
  def approve(request, approver, opts \\ [])

  def approve(%Request{} = request, %User{} = approver, opts) when is_list(opts) do
    process_approval(request, approver, :approve, opts)
  end

  @spec reject(%Request{}, %User{}, comment: map() | nil) :: tuple()
  def reject(request, approver, opts \\ [])

  def reject(%Request{} = request, %User{} = approver, opts) do
    process_approval(request, approver, :reject, opts)
  end

  defp process_approval(%Request{} = request, %User{} = approver, action, opts) do
    Multi.new()
    |> Multi.insert(:create_approval, change_approval(request, approver, action))
    |> Multi.update(:update_request, Workflow.transition(:service_request, request, action))
    |> create_comment_mult(approver, request, opts)
    |> Repo.transact()
    |> case do
      {:ok, %{update_request: request, create_approval: approval}} ->
        request =
          Repo.preload(request, [
            :category,
            :attachments,
            requestor_crew: [:users],
            assignee_crew: [:users]
          ])

        if request.status == :confirmation do
          Finalization.execute_after_finish(approver, request)
        end

        Itsm.PubSub.Helper.broadcast(Requests, {approver, :update_request, {request, approval}})
        {:ok, %{request: request, approval: approval}}

      error ->
        error
    end
  end

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

  def create_approval(%User{} = action_user, %Request{} = request, repo, opts \\ []) do
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

  defp create_comment_mult(%Ecto.Multi{} = multi, %User{} = approver, %_{} = resource,
         comment: comment
       ) do
    Multi.insert(
      multi,
      :create_comment,
      Comments.change_comment_for_resource(approver, resource, comment)
    )
  end

  defp create_comment_mult(multi, _action_user, _resource, _opts), do: multi
end
