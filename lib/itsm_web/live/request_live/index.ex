defmodule ItsmWeb.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Requests)

    {:ok, stream(socket, :requests, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, url, params)}
  end

  def handle_event("delete", %{"id" => id} = request_params, socket) do
    %{current_user: user} = socket.assigns
    request = Requests.get_request!(id)

    {:ok, request} = Requests.delete_request(user, request, request_params)

    {:noreply, stream_delete(socket, :requests, request)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, url, params) do
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
        [:category, :requestor, :assignee_crew]
      )

    socket
    |> assign(:page_title, "Listing Requests")
    |> assign(:results, value.results)
    |> stream(:requests, value.entries, reset: true)
  end

  defp apply_action(socket, :edit, _url, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Requests")
    |> assign(:request, Requests.get_request!(id))
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :request,
      resource_name: gettext("Request"),
      stream_name: :requests,
      push_patch: [to: ~p"/requests"]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
