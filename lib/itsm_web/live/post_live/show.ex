defmodule ItsmWeb.PostLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Posts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id, "board_id" => board_id}, _, socket)
      when board_id != nil and board_id != "" and is_binary(board_id) and
             byte_size(board_id) == 36 do
    target_board = Itsm.Boards.get_board!(board_id)

    {:noreply,
     socket
     |> assign(:board_name, Map.get(target_board, :name, ""))
     |> assign(:board_id, Map.get(target_board, :id, ""))
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Posts.get_post!(id) |> Posts.with_assoc([:board, :author]))
     |> Itsm.PubSub.Helper.subscribe(Posts, id: id)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, push_navigate(socket, to: ~p"/boards")}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{post: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :post, resource_name: gettext("Post")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_post),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []
end
