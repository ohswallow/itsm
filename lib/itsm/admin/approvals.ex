defmodule Itsm.Admin.Approvals do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Approval

  def get_approval!(id), do: Repo.get!(Approval, id) |> Repo.preload(request: :category)

  def list_approvals do
    Repo.all(Approval)
    |> Repo.preload(request: :category)
  end

  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs[:inserted_at])
  end

  defdelegate create_approval(attrs \\ %{}), to: Itsm.Approvals

  def update_approval(%Approval{} = approval, attrs) do
    approval
    |> Approval.admin_changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs[:inserted_at])
    |> Repo.update()
  end

  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
  end
end
