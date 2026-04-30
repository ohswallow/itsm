defmodule ItsmWeb.Admin.BoardLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Boards

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Itsm.Admin.Boards, id)
      Itsm.Utils.subscribes(Itsm.Admin.Boards)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:board, Boards.get_board!(id))}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Board"
  defp page_title(:edit), do: "Edit Board"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{board: %{id: id}}} = socket
        ) do
    opts =
      [context_key: :board, resource_name: gettext("Board")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_board),
    do: [push_navigate: [to: ~p"/admin/boards"]]

  defp push_event_action(_), do: []
end
