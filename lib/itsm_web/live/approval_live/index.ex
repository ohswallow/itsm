defmodule ItsmWeb.ApprovalLive.Index do
  use ItsmWeb, :live_view

  import ItsmWeb.ApprovalLive.Components

  alias Phoenix.LiveView.JS
  alias Itsm.Requests
  alias Itsm.Approvals
  alias Itsm.Workflow

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Approvals)

    {:ok, stream(socket, :requests, [])}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :approve, %{"request_id" => id}) do
    request = Requests.get_request!(id)

    socket
    |> assign(:page_title, Workflow.button_label(:service_request, request))
    |> assign(:request, request)
  end

  defp apply_action(socket, :reject, %{"request_id" => id}) do
    socket
    |> assign(:page_title, "반려")
    |> assign(:request, Requests.get_request!(id))
  end

  defp apply_action(socket, :feedback, %{"request_id" => id}) do
    socket
    |> assign(:page_title, "평가")
    |> assign(:request, Requests.get_request!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Approvals")
    |> stream(:requests, Approvals.list_pending_requests(socket.assigns.current_user),
      reset: true
    )
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :request,
      resource_name: gettext("Approval"),
      stream_name: :requests,
      push_patch: [to: ~p"/approvals"]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
