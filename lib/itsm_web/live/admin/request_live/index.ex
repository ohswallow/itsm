defmodule ItsmWeb.Admin.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests
  alias Itsm.Paging
  alias Itsm.Service.Request

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Requests)

    {:ok, stream(socket, :requests, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = request_params, socket) do
    {:ok, request} = Requests.delete_request(request_params)

    {:noreply, stream_delete(socket, :requests, request)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [
      default_columns: [:title, :description, :env, :requestor_name],
      preloads: [category: [:request_name, :name]]
    ]

    value =
      Paging.search_and_pagination(Request, params, url, opts)

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

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :request,
      resource_name: gettext("Request"),
      stream_name: :requests,
      push_patch: [to: ~p"/admin/requests?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
