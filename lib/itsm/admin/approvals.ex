defmodule Itsm.Admin.Approvals do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Approval

  def get_approval!(id), do: Repo.get!(Approval, id)

  def list_approvals do
    Repo.all(Approval)
  end

  def change_approval(%Approval{} = approval, approval_params \\ %{}) do
    Approval.changeset(approval, approval_params)
  end

  defdelegate create_approval(approval_params \\ %{}), to: Itsm.Approvals

  def update_approval(%Approval{} = approval, approval_params) do
    approval
    |> Approval.changeset(approval_params)
    |> Repo.update()
  end

  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
  end
end
