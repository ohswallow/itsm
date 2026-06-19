defmodule ItsmWeb.Admin.CommentLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket |> stream(:comments, []) |> Itsm.PubSub.Helper.subscribe(Comments, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = comment_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, comment} = Comments.delete_comment(action_user, comment_params)

    {:noreply, stream_delete(socket, :comments, comment)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:comments, Comment, params, url)
    |> assign(:page_title, "Listing Comments")
    |> assign(:comment, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Comment")
    |> assign(:comment, %Comment{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Comment")
    |> assign(:comment, Comments.get_comment!(id))
  end

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [:comment, {:user, :display_name}],
      preloads: [user: :display_name]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Comment"),
      target_key: :comments,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
