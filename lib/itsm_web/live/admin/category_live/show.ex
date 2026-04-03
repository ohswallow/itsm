defmodule ItsmWeb.Admin.CategoryLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Categories
  alias Itsm.Service.Category

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Category, id)
      Itsm.Utils.subscribes(Category)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:category, Categories.get_category!(id))}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Category"
  defp page_title(:edit), do: "Edit Category"

  defp handle_pubsub(
         user,
         event,
         %{id: id} = item,
         %{assigns: %{category: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :category, resource_name: gettext("Category")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_category),
    do: [push_navigate: [to: ~p"/admin/categories"]]

  defp push_event_action(_), do: []
end
