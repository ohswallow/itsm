defmodule ItsmWeb.AssetLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Assets
  alias Itsm.Assets.Asset

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Assets.subscribe_assets_list()

    {:ok, stream(socket, :assets, Assets.list_assets())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

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
    |> assign(:asset, nil)
  end

  # @impl true
  # def handle_info({ItsmWeb.AssetLive.FormComponent, {:saved, asset}}, socket) do
  #   {:noreply, stream_insert(socket, :assets, asset)}
  # end

  # @impl true
  # def handle_event("delete", %{"id" => id}, socket) do
  #   asset = Assets.get_asset!(id)
  #   {:ok, _} = Assets.delete_asset(asset)

  #   {:noreply, stream_delete(socket, :assets, asset)}
  # end

  @impl true
  def handle_info({Assets, [:asset, :created], asset}, socket) do
    # 새 자산이 생성되면 스트림의 맨 위(at: 0)에 꽂아 넣습니다.
    {:noreply, stream_insert(socket, :assets, asset, at: 0)}
  end

  def handle_info({Assets, [:asset, :updated], asset}, socket) do
    # 자산이 수정되면 스트림에서 해당 항목을 교체합니다.
    {:noreply, stream_insert(socket, :assets, asset)}
  end

  def handle_info({Assets, [:asset, :deleted], asset}, socket) do
    # 자산이 삭제되면 스트림에서 뺍니다.
    {:noreply, stream_delete(socket, :assets, asset)}
  end
end
