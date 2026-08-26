defmodule Itsm.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Itsm.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Itsm.Accounts.User

  defstruct user: nil, user_id: nil, role_ids: nil, role_names: nil, permissions: nil

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(%User{} = user) do
    Process.put(:current_user_id, user.id)

    %{role_ids: role_ids, role_names: role_names, perm_actions: perm_actions} =
      Enum.reduce(user.roles, %{role_ids: [], role_names: [], perm_actions: []}, fn role, acc ->
        perm_actions = Enum.map(role.permissions, & &1.action)

        %{
          role_ids: acc.role_ids ++ [role.id],
          role_names: acc.role_names ++ [role.name],
          perm_actions: acc.perm_actions ++ perm_actions
        }
      end)

    %__MODULE__{
      user_id: user.id,
      role_ids: role_ids,
      role_names: role_names,
      user: user,
      permissions: perm_actions
    }
  end

  def for_user(nil), do: nil
end
