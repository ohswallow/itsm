defmodule ItsmWeb.Admin.UserLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Accounts
  alias Itsm.Accounts.User
  alias Itsm.Admin.CommonCodes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(%User{}, user_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.live_action, fill_org_dept_codes(user_params))
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:organization_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:department_options, fn -> CommonCodes.get_select_options("부서") end)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, gettext("New User"))
    |> assign(:user, %User{})
    |> assign_new(:form, fn -> to_form(Accounts.change_user(%User{})) end)
    |> assign_new_options()
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    user = Accounts.get_user!(id)

    socket
    |> assign(:page_title, gettext("Edit User"))
    |> assign(:user, user)
    |> assign_new(:form, fn -> to_form(Accounts.change_user(user)) end)
    |> Itsm.PubSub.Helper.subscribe(Accounts, id: id, is_admin: true)
    |> assign_new_options()
  end

  defp save_user(socket, :edit, user_params) do
    %{current_scope: %{user: action_user}, user: user} = socket.assigns

    case Accounts.update_user(action_user, user, user_params) do
      {:ok, user} ->
        socket =
          if action_user.id == user.id,
            do:
              socket
              |> update(:current_scope, fn scope ->
                %{scope | user: user}
              end),
            else: socket

        {:noreply, socket |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Accounts.create_user(action_user, user_params) do
      {:ok, _user} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_user,
         %{id: id},
         %{assigns: %{user: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_user,
         %{id: id},
         %{assigns: %{user: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/users")}
  end

  defp fill_org_dept_codes(attrs) do
    org_code = attrs["organization_code"]
    org_name = CommonCodes.get_label("계열사", org_code)
    dept_code = attrs["department_code"]
    dept_name = CommonCodes.get_label("부서", dept_code)

    attrs
    |> Map.put("department", dept_name)
    |> Map.put("organization", org_name)
  end
end
