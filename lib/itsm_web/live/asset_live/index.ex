defmodule ItsmWeb.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Assets
  alias Itsm.Assets.Asset

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Asset)

    {:ok, stream(socket, :assets, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = asset_params, socket) do
    {:ok, asset} = Assets.delete_asset(asset_params)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  @impl true
  def handle_info({ItsmWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
    {:noreply, stream_insert(socket, :assets, asset)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Assets.get_asset!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assets")
    |> stream(:assets, Assets.list_assets())
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :asset,
      resource_name: gettext("Asset"),
      stream_name: :assets,
      push_patch: [to: ~p"/assets"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
