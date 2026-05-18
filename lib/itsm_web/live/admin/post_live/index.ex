defmodule ItsmWeb.Admin.PostLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Posts
  alias Itsm.Posts.Post
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:posts, []) |> Itsm.PubSub.Helper.subscribe(Posts, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = post_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, post} = Posts.delete_post(action_user, post_params)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [
      default_columns: [
        :title,
        :content,
        :metadata,
        author: :display_name,
        board: :name
      ],
      preloads: [author: :display_name, board: :name],
      range_columns: [:updated_at, :inserted_at]
    ]

    value =
      Post
      |> Paging.search_and_pagination(params, url, opts)

    socket
    |> assign(:results, value.results)
    |> stream(:posts, value.entries, reset: true)
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
    opts = [
      context_key: :post,
      resource_name: gettext("Post"),
      stream_name: :posts,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
