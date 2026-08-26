defmodule Itsm.Admin.Permissions do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.{User, Permission}
  alias Itsm.Utils

  def get_permission!(id), do: Repo.get!(Permission, id)

  def has_permission_for_roles_and_action(nil, _path, _act), do: false
  def has_permission_for_roles_and_action([], _path, _act), do: false

  def has_permission_for_roles_and_action(role_ids, path, act) do
    path = path |> Utils.replace_uuid("*") |> Utils.replace_number("*")
    action = ["#{path}:#{act}", "#{path}:*", "*:#{act}", "*:*"]

    Permission
    |> where([p], p.action in ^action)
    |> where([p], p.role_id in ^role_ids)
    |> Repo.exists?()
  end

  def get_permission_path do
    ItsmWeb.Router.__routes__()
    |> Enum.reject(&(&1.plug != Phoenix.LiveView.Plug))
    |> Enum.reject(&String.starts_with?(&1.path, "/dev"))
    |> Enum.reject(&String.starts_with?(&1.path, "/admin"))
    |> Enum.map(&Regex.replace(~r/:[^\/]*[id|token]\b/, &1.path, "*", global: true))
    |> Enum.concat(["/api/graphiql"])
  end

  def get_permission_act do
    ItsmWeb.Router.__routes__()
    |> Enum.reject(&(&1.plug != Phoenix.LiveView.Plug))
    |> Enum.reject(&String.starts_with?(&1.path, "/dev"))
    |> Enum.reject(&String.starts_with?(&1.path, "/admin"))
    |> Enum.map(&{Atom.to_string(&1.plug_opts), Atom.to_string(&1.plug_opts)})
    |> Enum.uniq()
    |> Enum.concat([{"*", "*"}])
  end

  def list_permissions, do: Repo.all(Permission)

  def create_permission(%User{} = action_user, attrs) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_permission, permission})
        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_permission(%User{} = action_user, %Permission{} = permission, attrs) do
    permission
    |> Permission.admin_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_permission, permission},
          id: permission.id
        )

        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_permission(%User{} = action_user, %{"id" => id}) do
    get_permission!(id)
    |> Repo.delete()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_permission, permission},
          id: permission.id
        )

        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_permission(%Permission{} = permission, attrs \\ %{}) do
    Permission.admin_changeset(permission, attrs)
  end

  def get_select_options, do: Permission |> select([p], {p.action, p.id}) |> Repo.all()
end
