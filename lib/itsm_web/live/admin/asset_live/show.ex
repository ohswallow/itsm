defmodule ItsmWeb.Admin.AssetLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Assets, id)
      Itsm.Utils.subscribes(Assets)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:asset, Assets.get_asset!(id))}
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    %{current_user: user} = socket.assigns

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: Itsm.Crews.search_live_select_crews(text, user)
    )

    {:noreply, socket}
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
      [context_key: :asset, resource_name: gettext("Asset")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_asset),
    do: [push_navigate: [to: ~p"/admin/assets"]]

  defp push_event_action(_), do: []
end
