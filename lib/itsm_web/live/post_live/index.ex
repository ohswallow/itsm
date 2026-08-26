defmodule ItsmWeb.PostLive.Index do
  alias Itsm.Boards
  use ItsmWeb, :live_view

  alias Itsm.Posts

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:posts, []) |> Itsm.PubSub.Helper.subscribe(Posts)}
  end

  def handle_params(%{"board_id" => board_id}, _url, socket)
      when board_id != nil and board_id != "" and is_binary(board_id) and
             byte_size(board_id) == 36 do
    %{assigns: %{current_scope: %{user: user}}} = socket
    target_board = Boards.get_board(board_id)

    {:noreply,
     socket
     |> assign(:board_name, Map.get(target_board, :name, ""))
     |> assign(:board_id, Map.get(target_board, :id, ""))
     |> stream(:posts, Posts.list_posts_by_user_or_board_id(user.id, board_id), reset: true)
     |> assign(:page_title, "Listing Posts")}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, push_navigate(socket, to: ~p"/boards")}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [resource_name: gettext("Post"), target_key: :posts]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
     |> stream_insert(:posts, item)}
  end
end
