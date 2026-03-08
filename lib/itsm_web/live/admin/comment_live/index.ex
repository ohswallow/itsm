defmodule ItsmWeb.Admin.CommentLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
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
  def handle_info({ItsmWeb.Admin.CommentLive.FormComponent, {:saved, comment}}, socket) do
    {:noreply, stream_insert(socket, :comments, comment)}
  end

  defp apply_action(socket, :index, params, url) do
    results =
      Paging.search_and_pagination(params, url, Comment, [:comment, {:user, :display_name}])

    socket
    |> assign(:results, results)
    |> stream(:comments, results.entries, reset: true)
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
end
