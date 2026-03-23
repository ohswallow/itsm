defmodule ItsmWeb.Admin.AssetLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:asset, id)
      Itsm.Utils.subscribes(:assets)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, Assets.get_asset!(id))}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"

  defp handle_pubsub(:update_asset, %{id: id} = asset, %{assigns: %{asset: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> assign(:asset, asset)
     |> put_flash(:info, gettext("Updated") <> " " <> gettext("Asset"))
     |> push_patch(to: ~p"/admin/assets/#{asset}")}
  end

  defp handle_pubsub(:delete_asset, %{id: id}, %{assigns: %{asset: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Asset"))
     |> push_navigate(to: ~p"/admin/assets")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
