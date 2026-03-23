defmodule ItsmWeb.Admin.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Assets.Asset
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribes(:assets)
    end

    {:ok, stream(socket, :assets, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    asset = Assets.get_asset!(id)
    {:ok, _} = Assets.delete_asset(asset)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, Asset, [
        :env,
        :name,
        :description,
        :location,
        :category,
        :affiliate,
        :region_type,
        :infra_type,
        :is_dmz_zone
      ])

    socket
    |> assign(:results, value.results)
    |> stream(:assets, value.entries, reset: true)
    |> assign(:page_title, "Listing Assets")
    |> assign(:asset, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Assets.get_asset!(id))
  end

  defp handle_pubsub(event, _asset, socket)
       when event in [:create_asset, :update_asset] do
    {:noreply,
     socket
     |> put_flash(
       :info,
       if(event == :create_asset,
         do: gettext("Created") <> " " <> gettext("Asset"),
         else: gettext("Updated") <> " " <> gettext("Asset")
       )
     )
     |> push_patch(to: ~p"/admin/assets?#{socket.assigns[:results][:params] || %{}}")}
  end

  defp handle_pubsub(:delete_asset, asset, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Asset"))
     |> stream_delete(:assets, asset)}
  end
end
