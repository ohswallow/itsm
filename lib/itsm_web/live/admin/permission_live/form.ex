defmodule ItsmWeb.Admin.PermissionLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Permissions
  alias Itsm.Accounts.Permission

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign_new_options()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"permission" => permission_params}, socket) do
    changeset = Permissions.change_permission(socket.assigns.permission, permission_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"permission" => permission_params}, socket) do
    save_permission(socket, socket.assigns.live_action, permission_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Permission")
    |> assign(:permission, %Permission{})
    |> assign_new(:form, fn -> to_form(Permissions.change_permission(%Permission{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    permission = Permissions.get_permission!(id)
    [path | act] = String.split(permission.action, ":")

    permission = %{permission | act: act, path: path}

    socket
    |> assign(:page_title, "Edit Permission")
    |> assign(:permission, permission)
    |> assign_new(:form, fn -> to_form(Permissions.change_permission(permission)) end)
    |> Itsm.PubSub.Helper.subscribe(Permission, id: id, is_admin: true)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:role_options, fn -> Itsm.Admin.Roles.get_select_options() end)
    |> assign_new(:path_options, fn -> Itsm.Admin.Permissions.get_permission_path() end)
    |> assign_new(:act_options, fn -> Itsm.Admin.Permissions.get_permission_act() end)
  end

  defp save_permission(socket, :edit, permission_params) do
    %{current_scope: %{user: action_user}, permission: permission} = socket.assigns

    permission_params =
      Map.put(
        permission_params,
        "action",
        "#{permission_params["path"]}:#{permission_params["act"]}"
      )

    case Permissions.update_permission(action_user, permission, permission_params) do
      {:ok, _permission} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/permissions")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_permission(socket, :new, permission_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    permission_params =
      Map.put(
        permission_params,
        "action",
        "#{permission_params["path"]}:#{permission_params["act"]}"
      )

    case Permissions.create_permission(action_user, permission_params) do
      {:ok, _permission} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/permissions")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_permission,
         %{id: id},
         %{assigns: %{permission: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_permission,
         %{id: id},
         %{assigns: %{permission: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/permissions")}
  end
end
