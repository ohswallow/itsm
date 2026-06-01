defmodule ItsmWeb.Admin.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Assets.Asset
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:assets, []) |> Itsm.PubSub.Helper.subscribe(Assets, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = asset_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, asset} = Assets.delete_asset(action_user, asset_params)

    {:noreply, stream_delete(socket, :assets, asset)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:assets, Asset, params, url)
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

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [
        :env,
        :name,
        :description,
        :location,
        :category,
        :affiliate,
        :region_type,
        :infra_type,
        :is_dmz_zone,
        [service_crew: :name, system_crew: :name]
      ],
      preloads: [service_crew: :name, system_crew: :name]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
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
