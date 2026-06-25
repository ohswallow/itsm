defmodule ItsmWeb.PostLive.Index do
  alias Itsm.Boards
  use ItsmWeb, :live_view

  alias Itsm.Posts
  alias Itsm.Posts.Post

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:posts, []) |> Itsm.PubSub.Helper.subscribe(Posts)}
  end

  def handle_params(%{"board_id" => board_id} = params, url, socket)
      when board_id != nil and board_id != "" and is_binary(board_id) and
             byte_size(board_id) == 36 do
    target_board = Boards.get_board(board_id)

    {:noreply,
     socket
     |> assign(:board_name, Map.get(target_board, :name, ""))
     |> assign(:board_id, Map.get(target_board, :id, ""))
     |> apply_action(socket.assigns.live_action, params, url)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, push_navigate(socket, to: ~p"/boards")}
  end

  def handle_event("delete", %{"id" => _id} = post_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, post} = Posts.delete_post(action_user, post_params)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, %{"board_id" => board_id} = _params, _url) do
    socket
    |> stream(:posts, Posts.list_posts_by_board_id(board_id), reset: true)
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Posts.get_post!(id))
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [resource_name: gettext("Post"), target_key: :posts]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
     |> stream_insert(:posts, item)}
  end
end
