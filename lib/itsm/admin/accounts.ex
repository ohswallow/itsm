defmodule Itsm.Admin.Accounts do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User

  def get_select_options() do
    User
    |> select([c], {c.display_name, c.id})
    |> Repo.all()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(%User{} = action_user, attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

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

  def delete_user(%User{} = action_user, %{"id" => id}) do
    get_user!(id)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.foreign_key_constraint(:id, name: :requests_requestor_id_fkey)
    |> Repo.delete()
    |> case do
      {:ok, user} ->
        Itsm.Accounts.UserToken.by_user_and_contexts_query(user, :all) |> Repo.delete_all()
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_user, user}, id: user.id)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
end
