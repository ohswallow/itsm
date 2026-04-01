defmodule ItsmWeb.Admin.RequestLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests
  alias Itsm.Service.Request

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Request, id)
      Itsm.Utils.subscribes(Request)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:request, Requests.get_request!(id))}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Request"
  defp page_title(:edit), do: "Edit Request"

  defp handle_pubsub(
         user,
         event,
         %{id: id} = item,
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :request, resource_name: gettext("Request")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_request),
    do: [push_navigate: [to: ~p"/admin/requests"]]

  defp push_event_action(_), do: []
end
