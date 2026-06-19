defmodule ItsmWeb.Admin.AssetLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Admin.Crews

  def mount(_params, _session, socket) do
    {:ok,
     socket |> stream(:assets, []) |> assign(all_ids: [], selected_ids: [], all_selected: false)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {assets, all_ids} =
      Assets.list_assets_with_crew()
      |> Enum.reduce({[], []}, fn asset, {assets_acc, ids_acc} ->
        if asset.id != id,
          do: {[asset | assets_acc], [asset.id | ids_acc]},
          else: {assets_acc, ids_acc}
      end)

    assets = Enum.reverse(assets)
    all_ids = Enum.reverse(all_ids)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(
       :asset,
       Assets.get_asset!(id) |> Assets.with_assoc([[service_crew: :users], [system_crew: :users]])
     )
     |> stream(:assets, assets)
     |> assign(all_ids: all_ids, selected_ids: [], all_selected: false)
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
        {:noreply,
         socket
         |> put_flash(:info, "#{length(selected_ids)}건의 자산이 모두 성공적으로 연결되었습니다.")
         |> assign(selected_ids: [], all_selected: false)}

      {:error, {:connect, failed_id}, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        {:noreply,
         socket
         |> put_flash(:error, "자산(ID: #{failed_id}) 연동 중 오류 발생")
         |> assign(:form, to_form(changeset))}

      result ->
        IO.inspect(result, label: "result")

        {:noreply,
         socket
         |> put_flash(:info, "result")}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Asset"
  defp page_title(:edit), do: "Edit Asset"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :asset, resource_name: gettext("Asset")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_asset),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []
end
