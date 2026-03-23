defmodule Itsm.Admin.Approvals do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Approval

  def get_approval!(id), do: Repo.get!(Approval, id)

  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def update_approval(%Approval{} = approval, attrs) do
    approval
    |> Approval.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, approval} ->
        Itsm.Utils.broadcast(:approval, {:update_approval, approval})
        Itsm.Utils.broadcasts(:approvals, {:update_approval, approval})
        {:ok, approval}

      {:error, _} = error ->
        error
    end
  end

  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
    |> case do
      {:ok, approval} ->
        Itsm.Utils.broadcast(:approval, {:delete_approval, approval})
        Itsm.Utils.broadcasts(:approvals, {:delete_approval, approval})
        {:ok, approval}

      {:error, _} = error ->
        error
    end
  end

  def preload_category(%Approval{} = approval) do
    approval |> Repo.preload(request: :category)
  end
end
