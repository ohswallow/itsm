defmodule ItsmWeb.Admin.CommentLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Comments, id)
      Itsm.Utils.subscribes(Comments)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:comment, Comments.get_comment!(id) |> Comments.with_assoc(:user))}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Comment"
  defp page_title(:edit), do: "Edit Comment"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{comment: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :comment, resource_name: gettext("Comment")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_comment),
    do: [push_navigate: [to: ~p"/admin/comments"]]

  defp push_event_action(_), do: []
end
