defmodule ItsmWeb.Admin.UserLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Accounts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user, Accounts.get_user!(id))
     |> Itsm.PubSub.Helper.subscribe(Accounts, id: id, is_admin: true)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show User"
  defp page_title(:edit), do: "Edit User"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{user: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :user, resource_name: gettext("User")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_user),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []
end
