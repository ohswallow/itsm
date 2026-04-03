defmodule ItsmWeb.Admin.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Assets.Asset
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Asset)

    {:ok, stream(socket, :assets, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = asset_params, socket) do
    {:ok, asset} = Assets.delete_asset(asset_params)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(
        params,
        url,
        Asset,
        [
          :env,
          :name,
          :description,
          :location,
          :category,
          :affiliate,
          :region_type,
          :infra_type,
          :is_dmz_zone,
          service_crew: :name,
          system_crew: :name
        ],
        service_crew: :name,
        system_crew: :name
      )

    socket
    |> assign(:results, value.results)
    |> stream(:assets, value.entries, reset: true)
    |> assign(:page_title, "Listing Assets")
    |> assign(:asset, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Asset")
    |> assign(:asset, %Asset{} |> Itsm.Assets.with_assoc([:service_crew, :system_crew]))
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Asset")
    |> assign(:asset, Assets.get_asset!(id))
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :asset,
      resource_name: gettext("Asset"),
      stream_name: :assets,
      push_patch: [to: ~p"/admin/assets?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
