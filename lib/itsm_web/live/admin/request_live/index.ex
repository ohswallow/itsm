defmodule ItsmWeb.Admin.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Requests")
     |> stream(:requests, Requests.list_requests())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, Requests.get_request!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, %Itsm.Service.Request{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Requests")
    |> assign(:request, nil)
  end

  @impl true
  def handle_info({ItsmWeb.Admin.RequestLive.FormComponent, {:saved, request}}, socket) do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Requests.get_request!(id)
    {:ok, _} = Requests.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end
end
