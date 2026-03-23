defmodule ItsmWeb.Admin.ApprovalLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:approval, id)
      Itsm.Utils.subscribes(:approvals)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:approval, Approvals.get_approval!(id) |> Approvals.preload_category())}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Approval"
  defp page_title(:edit), do: "Edit Approval"

  defp handle_pubsub(
         :update_approval,
         %{id: id} = approval,
         %{assigns: %{approval: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:approval, Approvals.preload_category(approval))
     |> put_flash(:info, gettext("Updated") <> " " <> gettext("Approval"))
     |> push_patch(to: ~p"/admin/approvals/#{approval}")}
  end

  defp handle_pubsub(:delete_approval, %{id: id}, %{assigns: %{approval: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Approval"))
     |> push_navigate(to: ~p"/admin/approvals")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
