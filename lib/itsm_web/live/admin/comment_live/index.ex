defmodule ItsmWeb.Admin.CommentLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribes(:comments)
    end

    {:ok, stream(socket, :comments, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    comment = Comments.get_comment!(id)
    {:ok, _} = Comments.delete_comment(comment)

    {:noreply, stream_delete(socket, :comments, comment)}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(
        params,
        url,
        Comment,
        [:comment, {:user, :display_name}],
        user: :display_name
      )

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

  defp handle_pubsub(event, _comment, socket)
       when event in [:create_comment, :update_comment] do
    {:noreply,
     socket
     |> put_flash(
       :info,
       if(event == :create_comment,
         do: gettext("Created") <> " " <> gettext("Comment"),
         else: gettext("Updated") <> " " <> gettext("Comment")
       )
     )
     |> push_patch(to: ~p"/admin/comments?#{socket.assigns[:results][:params] || %{}}")}
  end

  defp handle_pubsub(:delete_comment, comment, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Comment"))
     |> stream_delete(:comments, comment)}
  end
end
