defmodule ItsmWeb.Admin.PostLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Posts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Itsm.Admin.Posts, id)
      Itsm.Utils.subscribes(Itsm.Admin.Posts)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Posts.get_post!(id) |> Posts.with_assoc([:board, :author]))}
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
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_post),
    do: [push_navigate: [to: ~p"/admin/posts"]]

  defp push_event_action(_), do: []
end
