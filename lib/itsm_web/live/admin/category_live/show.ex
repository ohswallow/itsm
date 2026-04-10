defmodule ItsmWeb.Admin.CategoryLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Categories

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Categories, id)
      Itsm.Utils.subscribes(Categories)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:category, Categories.get_category!(id))}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Category"
  defp page_title(:edit), do: "Edit Category"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{category: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :category, resource_name: gettext("Category")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_category),
    do: [push_navigate: [to: ~p"/admin/categories"]]

  defp push_event_action(_), do: []
end
