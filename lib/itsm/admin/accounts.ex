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

  defdelegate create_user(attrs \\ %{}), to: Itsm.Accounts

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :update_user, user})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :update_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate delete_user(attrs), to: Itsm.Accounts

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
end
