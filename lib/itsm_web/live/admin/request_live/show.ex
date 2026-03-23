defmodule ItsmWeb.Admin.RequestLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:request, id)
      Itsm.Utils.subscribes(:requests)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:request, Requests.get_request!(id))}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Request"
  defp page_title(:edit), do: "Edit Request"

  defp handle_pubsub(
         :update_request,
         %{id: id} = request,
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:request, request)
     |> put_flash(:info, gettext("Updated") <> " " <> gettext("Request"))
     |> push_patch(to: ~p"/admin/requests/#{request}")}
  end

  defp handle_pubsub(:delete_request, %{id: id}, %{assigns: %{request: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Request"))
     |> push_navigate(to: ~p"/admin/requests")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
