defmodule ItsmWeb.AssetLive.Show do
  use ItsmWeb, :live_view

  import ItsmWeb.ResourceComponents
  alias Itsm.Assets
  alias Itsm.Assets.Asset
  alias Itsm.Assets.ResourceCardData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if connected?(socket) do
      Itsm.Utils.subscribe(Asset, id)
      Itsm.Utils.subscribes(Asset)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, Assets.get_asset_with_relations!(id))
     |> assign_new_options()}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket |> assign_new(:affiliate_optios, Itsm.CommonCodes.get_select_options("계열사"))
  end

  # 리소스 섹션 정의 — 새 인스턴스 타입 추가 시 여기에 항목만 추가
  defp resource_sections(asset) do
    [
      %{
        title: "Operating System",
        icon: "hero-computer-desktop",
        icon_class: "text-indigo-500",
        items: build_items(asset.os_instance)
      }
      # TODO : DB 추가 시 아래처럼 항목 추가
      # %{
      #   title: "Database",
      #   icon: "hero-circle-stack",
      #   icon_class: "text-emerald-500",
      #   items: build_items(asset.db_instances)
      # },
      # TODO : WAS 추가 시 아래처럼 항목 추가
      # %{
      #   title: "WAS",
      #   icon: "hero-cube",
      #   icon_class: "text-orange-500",
      #   items: build_was_data(asset.was_instances)
      # }
    ]
  end

  # Protocol 기반 범용 변환 함수
  defp build_items(nil), do: []
  defp build_items(%Ecto.Association.NotLoaded{}), do: []

  defp build_items(instance) when is_struct(instance),
    do: [ResourceCardData.to_card_item(instance)]

  defp build_items(instances) when is_list(instances) do
    Enum.map(instances, &ResourceCardData.to_card_item/1)
  end

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"

  defp handle_pubsub(
         user,
         event,
         %{id: id} = item,
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :asset, resource_name: gettext("Asset")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_asset),
    do: [push_navigate: [to: ~p"/assets"]]

  defp push_event_action(_), do: []
end
