defmodule ItsmWeb.Admin.AssetLive.AssetShadowLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.AssetsShadow
  alias Itsm.Admin.Crews

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:assets_shadow, [])}
  end

  def handle_params(%{"id" => id}, _, socket) do
    asset_shadow =
      AssetsShadow.get_asset_shadow!(id)
      |> AssetsShadow.with_assoc([[service_crew: :users], [system_crew: :users]])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset_shadow, asset_shadow)
     |> Itsm.PubSub.Helper.subscribe(AssetsShadow, id: id, is_admin: true)}
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    %{current_scope: %{user: user}} = socket.assigns

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: Crews.search_live_select_crews(text, user)
    )

    {:noreply, socket}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show AssetShadow"
  defp page_title(:edit), do: "Edit AssetShadow"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :asset, resource_name: gettext("AssetShadow")]
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
