defmodule ItsmWeb.Admin.AssetLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Admin.Crews

  def mount(_params, _session, socket) do
    {:ok,
     socket |> stream(:assets, []) |> assign(all_ids: [], selected_ids: [], all_selected: false)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    asset =
      Assets.get_asset!(id) |> Assets.with_assoc([[service_crew: :users], [system_crew: :users]])

    {:noreply,
     socket
     |> assign(:page_title, gettext("Show Asset"))
     |> assign(:asset, asset)
     |> setup_relation_assets(asset)
     |> Itsm.PubSub.Helper.subscribe(Assets, id: id, is_admin: true)}
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    %{current_scope: %{user: user}} = socket.assigns

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: Crews.search_live_select_crews(text, user)
    )

    {:noreply, socket}
  end

  def handle_event("update_selection", %{"_target" => ["toggle_all"]}, socket) do
    new_selected_ids = if socket.assigns.all_selected, do: [], else: socket.assigns.all_ids

    {:noreply,
     socket |> assign(selected_ids: new_selected_ids, all_selected: !socket.assigns.all_selected)}
  end

  def handle_event("update_selection", %{"selected_ids" => selected_ids}, socket) do
    all_selected = Enum.count(selected_ids) == Enum.count(socket.assigns.all_ids)

    {:noreply, assign(socket, selected_ids: selected_ids, all_selected: all_selected)}
  end

  def handle_event("update_selection", _params, socket) do
    {:noreply, assign(socket, selected_ids: [], all_selected: false)}
  end

  def handle_event("batch_action", %{"selected_ids" => selected_ids}, socket) do
    %{assigns: %{asset: asset}} = socket

    case Assets.connect_assets(asset, selected_ids) do
      {:ok, _results} ->
        new_asset =
          Assets.get_asset!(asset.id)
          |> Assets.with_assoc([[service_crew: :users], [system_crew: :users]])

        {:noreply,
         socket
         |> put_flash(:info, "#{length(selected_ids)}건의 자산이 모두 성공적으로 연결되었습니다.")
         |> assign(:asset, new_asset)
         |> setup_relation_assets(new_asset)}

      {:error, {:connect, failed_id}, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        {:noreply,
         socket
         |> put_flash(:error, "자산(ID: #{failed_id}) 연동 중 오류 발생")
         |> assign(:form, to_form(changeset))}

      _ ->
        {:noreply,
         socket
         |> put_flash(:info, "result")}
    end
  end

  def handle_event("disconnect_asset", %{"id" => asset_id}, socket) do
    %{assigns: %{asset: asset}} = socket

    case Assets.disconnect_assets(asset.id, asset_id) do
      {:ok, _} ->
        new_asset =
          Assets.get_asset!(asset.id)
          |> Assets.with_assoc([[service_crew: :users], [system_crew: :users]])

        {:noreply,
         socket
         |> put_flash(:info, "자산이 성공적으로 연결 해제되었습니다.")
         |> assign(:asset, new_asset)
         |> setup_relation_assets(new_asset)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "자산 연결 해제 중 오류 발생: #{inspect(reason)}")}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :asset, resource_name: gettext("Asset")]
      |> push_event_action(event)

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(opts, :delete_asset),
    do: Keyword.put(opts, :push_navigate, to: ~p"/admin/assets")

  defp push_event_action(opts, _), do: opts

  defp setup_relation_assets(socket, asset) do
    {assets, all_ids} =
      Assets.filter_assets_for_relation(Assets.list_assets_with_crew(), asset)

    socket
    |> stream(:assets, assets)
    |> assign(all_ids: all_ids)
    |> assign(selected_ids: [], all_selected: false)
  end
end
