defmodule Itsm.Admin.Roles do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.{User, Role}

  def get_role!(id), do: Repo.get!(Role, id)
  def get_role_by_name(name), do: Repo.get_by(Role, name: name)

  def list_roles, do: Repo.all(Role)
  def list_roles_by_ids(ids), do: Role |> where([r], r.id in ^ids) |> Repo.all()

  def create_role(%User{} = action_user, attrs) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_role, role})
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_role(%User{} = action_user, %Role{} = role, attrs) do
    role
    |> Role.admin_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_role, role}, id: role.id)
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_role(%User{} = action_user, %{"id" => id}) do
    get_role!(id)
    |> Repo.delete()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_role, role}, id: role.id)
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.admin_changeset(role, attrs)
  end

  def get_select_options, do: Role |> select([r], {r.name, r.id}) |> Repo.all()
end
