defmodule ItsmWeb.Admin.ApprovalLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Approvals, id)
      Itsm.Utils.subscribes(Approvals)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:approval, Approvals.get_approval!(id) |> Approvals.preload_category())}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Approval"
  defp page_title(:edit), do: "Edit Approval"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{approval: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :approval, resource_name: gettext("Approval")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_approval),
    do: [push_navigate: [to: ~p"/admin/approvals"]]

  defp push_event_action(_), do: []
end
