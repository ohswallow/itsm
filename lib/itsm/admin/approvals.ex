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
        event = :update_approval
        Itsm.Utils.broadcast(Approval, {attrs["current_user"], event, approval})
        Itsm.Utils.broadcasts(Approval, {attrs["current_user"], event, approval})
        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_approval(%{"id" => id} = attrs) do
    Repo.delete(get_approval!(id))
    |> case do
      {:ok, approval} ->
        event = :delete_approval
        Itsm.Utils.broadcast(Approval, {attrs["current_user"], event, approval})
        Itsm.Utils.broadcasts(Approval, {attrs["current_user"], event, approval})
        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def preload_category(%Approval{} = approval) do
    approval |> Repo.preload(request: :category)
  end
end
