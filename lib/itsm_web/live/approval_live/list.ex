# lib/itsm_web/live/approval_live/list.ex

defmodule ItsmWeb.ApprovalLive.List do
  use ItsmWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Itsm.Requests
  alias Itsm.Approvals
  alias Itsm.Workflow
  alias Itsm.Service.Request

  # ==================================================
  # Lifecycle
  # ==================================================

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :requests, Approvals.list_pending_requests(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    Approvals.subscribe_approvals_list()
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

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
    |> assign(:request, nil)
  end

  # ==================================================
  # Render
  # ==================================================

  @impl true
  def render(assigns) do
    ~H"""
    <.modal
      :if={@live_action in [:approve, :reject]}
      id="approval-modal"
      show
      on_cancel={JS.navigate(~p"/approvals")}
    >
      <.live_component
        module={ItsmWeb.CreateCommentDialog}
        id={@request.id}
        title={@page_title}
        action={@live_action}
        request={@request}
        current_user={@current_user}
      />
    </.modal>

    <.modal
      :if={@live_action == :feedback}
      id="feedback-modal"
      show
      on_cancel={JS.navigate(~p"/approvals")}
    >
      <.live_component
        module={ItsmWeb.EvaluationDialog}
        id={@request.id}
        title={@page_title}
        action={@live_action}
        request={@request}
        crew_id={@request.assignee_crew_id}
        current_user={@current_user}
      />
    </.modal>

    <.header>Listing Approvals</.header>

    <.table
      id="requests"
      rows={@streams.requests}
      row_click={
        fn {_id, request} -> JS.navigate("/#{request.category.request_name}/#{request.id}") end
      }
    >
      <:col :let={{_id, request}} label={gettext("Title")}>
        <div class="w-[90px] truncate">{request.title}</div>
      </:col>

      <:col :let={{_id, request}} label={gettext("Environment")}>{request.env}</:col>

      <:col :let={{id, request}} label={gettext("Due Date")}>
        <span id={"due_date_#{id}"} phx-hook="LocalTime.ToLocale" utc-value={request.due_date}></span>
      </:col>

      <:col :let={{_id, request}} label={gettext("Request Name")}>{request.category.name}</:col>

      <:col :let={{_id, request}} label={gettext("Requestor Name")}>{request.requestor_name}</:col>

      <:col :let={{_id, request}} label={gettext("Status")}>
        {Workflow.status_label(:service_request, request)}
      </:col>

      <:action :let={{_id, request}}><.action_cell request={request} /></:action>
    </.table>
    """
  end

  # ==================================================
  # Components
  # ==================================================

  defp action_cell(assigns) do
    assigns = assign(assigns, :action_info, get_action_info(assigns.request))

    ~H"""
    <%= case @action_info do %>
      <% :closed -> %>
        <span class="text-gray-400">closed</span>
      <% {:feedback, label} -> %>
        <.link
          navigate={~p"/approvals/#{@request.id}/feedback"}
          class="text-green-600 font-bold hover:underline"
        >
          {label}
        </.link>
      <% {:approve, label, true} -> %>
        <.link
          navigate={~p"/approvals/#{@request.id}/approve"}
          class="text-blue-600 hover:underline font-bold"
        >
          {label}
        </.link>
        <.link
          navigate={~p"/approvals/#{@request.id}/reject"}
          class="text-red-600 ml-2 hover:underline"
        >
          반려
        </.link>
      <% {:approve, label, false} -> %>
        <.link
          navigate={~p"/approvals/#{@request.id}/approve"}
          class="text-indigo-600 font-bold hover:underline"
        >
          {label}
        </.link>
    <% end %>
    """
  end

  defp get_action_info(%Request{} = request) do
    cond do
      Workflow.closed?(request) ->
        :closed

      Workflow.action_type(:service_request, request) == :feedback ->
        {:feedback, Workflow.button_label(:service_request, request)}

      true ->
        {:approve, Workflow.button_label(:service_request, request),
         Workflow.rejectable?(:service_request, request)}
    end
  end

  # ==================================================
  # Event Handlers
  # ==================================================

  @impl true
  def handle_info({:request_updated, _updated_request}, socket) do
    {:noreply,
     stream(socket, :requests, Approvals.list_pending_requests(socket.assigns.current_user),
       reset: true
     )}
  end

  def handle_info({:request_created, _created_request}, socket) do
    {:noreply,
     stream(socket, :requests, Approvals.list_pending_requests(socket.assigns.current_user),
       reset: true
     )}
  end
end
