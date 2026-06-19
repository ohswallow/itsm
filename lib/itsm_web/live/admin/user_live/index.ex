defmodule ItsmWeb.Admin.UserLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Accounts
  alias Itsm.Accounts.User
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:users, []) |> Itsm.PubSub.Helper.subscribe(Accounts, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = user_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Accounts.delete_user(action_user, user_params) do
      {:ok, user} ->
        socket =
          if action_user.id == user.id, do: redirect(socket, to: ~p"/users/log_out"), else: socket

        {:noreply, stream_delete(socket, :users, user)}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, put_flash(socket, :error, "삭제 실패: 자식 데이터가 존재합니다.")}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:users, User, params, url)
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

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [
        :email,
        :employee_number,
        :display_name,
        :organization,
        :organization_code,
        :department,
        :department_code,
        :role
      ]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("User"),
      target_key: :users,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
