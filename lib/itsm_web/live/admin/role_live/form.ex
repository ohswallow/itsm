defmodule ItsmWeb.Admin.RoleLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Roles
  alias Itsm.Accounts.Role

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"role" => role_params}, socket) do
    changeset = Roles.change_role(socket.assigns.role, role_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"role" => role_params}, socket) do
    save_role(socket, socket.assigns.live_action, role_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Role")
    |> assign(:role, %Role{})
    |> assign_new(:form, fn -> to_form(Roles.change_role(%Role{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    role = Roles.get_role!(id)

    socket
    |> assign(:page_title, "Edit Role")
    |> assign(:role, role)
    |> assign_new(:form, fn -> to_form(Roles.change_role(role)) end)
    |> Itsm.PubSub.Helper.subscribe(Role, id: id, is_admin: true)
  end

  defp save_role(socket, :edit, role_params) do
    %{current_scope: %{user: action_user}, role: role} = socket.assigns

    case Roles.update_role(action_user, role, role_params) do
      {:ok, _role} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/roles")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_role(socket, :new, role_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Roles.create_role(action_user, role_params) do
      {:ok, _role} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/roles")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_role,
         %{id: id},
         %{assigns: %{role: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_role,
         %{id: id},
         %{assigns: %{role: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/roles")}
  end
end
