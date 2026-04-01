defmodule ItsmWeb.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Requests
  alias Itsm.Service.Request

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Request)

    {:ok, stream(socket, :requests, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = request_params, socket) do
    %{current_user: user, request: request} = socket.assigns

    {:ok, request} = Requests.delete_request(user, request, request_params)

    {:noreply, stream_delete(socket, :requests, request)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Requests")
    |> stream(:requests, Requests.list_requests(), reset: true)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Requests")
    |> assign(:request, %Request{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Requests")
    |> assign(:request, Requests.get_request!(id))
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :request,
      resource_name: gettext("Request"),
      stream_name: :requests,
      push_patch: [to: ~p"/requests"]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
