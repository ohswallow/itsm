defmodule Itsm.Admin.Approvals do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Service.Approval

  def get_approval!(id), do: Repo.get!(Approval, id)

  defdelegate list_approvals_by_request(request_id), to: Itsm.Approvals

  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def update_approval(%User{} = action_user, %Approval{} = approval, attrs) do
    approval
    |> Approval.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, approval} ->
        event = :update_approval
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, approval}, id: approval.id)

        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_approval(%User{} = action_user, %{"id" => id}) do
    Repo.delete(get_approval!(id))
    |> case do
      {:ok, approval} ->
        event = :delete_approval
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, approval}, id: approval.id)

        {:ok, approval}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def preload_category(%Approval{} = approval) do
    approval |> Repo.preload(request: :category)
  end
end
