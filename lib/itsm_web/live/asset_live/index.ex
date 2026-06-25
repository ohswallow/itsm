defmodule ItsmWeb.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Assets
  alias Itsm.Assets.Asset

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:assets, []) |> Itsm.PubSub.Helper.subscribe(Assets)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("delete", %{"id" => _id} = asset_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, asset} = Assets.delete_asset(action_user, asset_params)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  def handle_info({ItsmWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
    {:noreply, stream_insert(socket, :assets, asset)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

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

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Asset"),
      target_key: :assets,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
