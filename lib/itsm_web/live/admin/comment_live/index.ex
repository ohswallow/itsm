defmodule ItsmWeb.Admin.CommentLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Comments)

    {:ok, stream(socket, :comments, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = comment_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, comment} = Comments.delete_comment(action_user, comment_params)

    {:noreply, stream_delete(socket, :comments, comment)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [
      default_columns: [:comment, {:user, :display_name}],
      preloads: [user: :display_name]
    ]

    value = Paging.search_and_pagination(Comment, params, url, opts)

    socket
    |> assign(:results, value.results)
    |> stream(:comments, value.entries, reset: true)
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

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :comment,
      resource_name: gettext("Comment"),
      stream_name: :comments,
      push_patch: [to: ~p"/admin/comments?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
