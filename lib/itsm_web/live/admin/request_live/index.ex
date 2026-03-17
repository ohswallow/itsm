defmodule ItsmWeb.Admin.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests
  alias Itsm.Paging
  alias Itsm.Service.Request

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :requests, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Requests.get_request!(id)
    {:ok, _} = Requests.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(
        params,
        url,
        Request,
        [
          :title,
          :description,
          :env,
          :requestor_name
        ],
        category: [:request_name, :name]
      )

    socket
    |> assign(:results, value.results)
    |> stream(:requests, value.entries, reset: true)
    |> assign(:page_title, "Listing Requests")
    |> assign(:request, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, %Request{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, Requests.get_request!(id))
  end
end
