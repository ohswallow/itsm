defmodule Itsm.Permissions do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.Permission
  alias Itsm.Utils

  def has_permission_for_roles_and_action(nil, _path, _act), do: false
  def has_permission_for_roles_and_action([], _path, _act), do: false

  def has_permission_for_roles_and_action(role_ids, path, act) do
    path = path |> Utils.replace_uuid("*") |> Utils.replace_number("*")
    actions = ["#{path}:#{act}", "#{path}:*", "*:#{act}", "*:*"]

    Permission
    |> where([p], p.action in ^actions)
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
end
