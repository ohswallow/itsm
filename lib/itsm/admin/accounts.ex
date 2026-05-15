defmodule Itsm.Admin.Accounts do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User

  def get_select_options() do
    User
    |> select([c], {c.display_name, c.id})
    |> Repo.all()
  end

  defdelegate get_user!(id), to: Itsm.Accounts

  defdelegate list_users, to: Itsm.Accounts

  defdelegate create_user(action_user, attrs), to: Itsm.Accounts

  defdelegate register_user(action_user, attrs), to: Itsm.Accounts

  def update_user(%User{} = action_user, %User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_user, user}, id: user.id)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate delete_user(action_user, attrs), to: Itsm.Accounts

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
end
