defmodule ItsmWeb.Admin.UserLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Accounts
  alias Itsm.Accounts.User
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Accounts)

    {:ok, stream(socket, :users, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = user_params, socket) do
    {:ok, user} = Accounts.delete_user(user_params)

    {:noreply, stream_delete(socket, :users, user)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, User, [
        :email,
        :password,
        :hashed_password,
        :current_password,
        :confirmed_at,
        :employee_number,
        :display_name,
        :organization,
        :organization_code,
        :department,
        :department_code,
        :role
      ])

    socket
    |> assign(:results, value.results)
    |> stream(:users, value.entries, reset: true)
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :user,
      resource_name: gettext("User"),
      stream_name: :users,
      push_patch: [to: ~p"/admin/users?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
