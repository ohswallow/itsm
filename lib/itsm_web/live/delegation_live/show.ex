defmodule ItsmWeb.DelegationLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Delegations

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if connected?(socket) do
      Itsm.Utils.subscribe(Delegations, id)
      Itsm.Utils.subscribes(Delegations)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:delegation, Delegations.get_delegation!(id))}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Delegation"
  defp page_title(:edit), do: "Edit Delegation"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{delegation: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :delegation, resource_name: gettext("Delegation")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_delegation),
    do: [push_navigate: [to: ~p"/delegations"]]

  defp push_event_action(_), do: []
end
