defmodule ItsmWeb.Admin.CategoryLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Categories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:category, id)
      Itsm.Utils.subscribes(:categories)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:category, Categories.get_category!(id))}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Category"
  defp page_title(:edit), do: "Edit Category"

  defp handle_pubsub(
         :update_category,
         %{id: id} = category,
         %{assigns: %{category: %{id: id}}} = socket
       ) do
    {
      :noreply,
      socket
      |> assign(:category, category)
      |> put_flash(:info, gettext("Updated") <> " " <> gettext("Category"))
      |> push_patch(to: ~p"/admin/categories/#{category}")
    }
  end

  defp handle_pubsub(:delete_category, %{id: id}, %{assigns: %{category: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Category"))
     |> push_navigate(to: ~p"/admin/categories")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
