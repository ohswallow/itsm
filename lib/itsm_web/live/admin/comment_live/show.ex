defmodule ItsmWeb.Admin.CommentLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:comment, id)
      Itsm.Utils.subscribes(:comments)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:comment, Comments.get_comment!(id) |> Comments.preload_user())}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Comment"
  defp page_title(:edit), do: "Edit Comment"

  defp handle_pubsub(
         :update_comment,
         %{id: id} = comment,
         %{assigns: %{comment: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:comment, comment)
     |> put_flash(:info, gettext("Updated") <> " " <> gettext("Comment"))
     |> push_patch(to: ~p"/admin/comments/#{comment}")}
  end

  defp handle_pubsub(:delete_comment, %{id: id}, %{assigns: %{comment: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Comment"))
     |> push_navigate(to: ~p"/admin/comments")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
