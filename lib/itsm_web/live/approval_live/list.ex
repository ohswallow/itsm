defmodule ItsmWeb.ApprovalLive.List do
  use ItsmWeb, :live_view
  alias Itsm.Service
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:requests, Service.list_assignee_requests(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    Service.subscribe_approvals_list()

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :approve, %{"request_id" => id}) do
    socket
    |> assign(:page_title, "승인")
    |> assign(:request, Service.get_request!(id))
  end

  defp apply_action(socket, :reject, %{"request_id" => id}) do
    socket
    |> assign(:page_title, "반려")
    |> assign(:request, Service.get_request!(id))
  end

  defp apply_action(socket, :feedback, %{"request_id" => id}) do
    socket
    |> assign(:page_title, "평가")
    |> assign(:request, Service.get_request!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Approvals")
    |> assign(:request, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- ✅ 모달은 부모가 책임 -->
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
        fn {_id, request} -> JS.navigate(~p"/#{request.category.request_name}/#{request.id}") end
      }
    >
      <:col :let={{_id, request}} label="Title">{request.title}</:col>
      
      <:col :let={{_id, request}} label="Description">
        <div class="w-[90px] truncate">{request.description}</div>
      </:col>
      
      <:col :let={{_id, request}} label="Env">{request.env}</:col>
      
      <:col :let={{_id, request}} label="Due date">{request.due_date}</:col>
      
      <:col :let={{_id, request}} label="Request Name">{request.category.name}</:col>
      
      <:col :let={{_id, request}} label="Requestor Name">{request.requestor_name}</:col>
      
      <:col :let={{_id, request}} label="Status">{request.status}</:col>
      
      <:col :let={{_id, request}} label="Assignee Crew">{request.assignee_crew_id}</:col>
      
      <:col :let={{_id, request}} label="Assignee Name">{request.assignee_name}</:col>
      
      <%!-- <:action :let={{_id, request}}>
        <.link navigate={~p"/approvals/#{request.id}/approve"}>승인</.link>
      </:action>

      <:action :let={{_id, request}}>
        <.link navigate={~p"/approvals/#{request.id}/reject"}>반려</.link>
      </:action> --%>
      <:action :let={{_id, request}}>
        <%= cond do %>
          <% request.status == :verify -> %>
            <.link navigate={~p"/approvals/#{request.id}/feedback"} class="text-green-600 font-medium">
              평가
            </.link>
          <% request.status != :closed -> %>
            <.link navigate={~p"/approvals/#{request.id}/approve"} class="text-blue-600">승인</.link>
            <.link navigate={~p"/approvals/#{request.id}/reject"} class="text-red-600 ml-2">반려</.link>
          <% true -> %>
            <span class="text-gray-400">closed</span>
        <% end %>
      </:action>
      
      <%!-- <:action :let={{_id, request}}>
        <.link :if={request.status == :verify} navigate={~p"/approvals/#{request.id}/feedback"}>
          평가
        </.link>
      </:action>

      <:action :let={{_id, request}}>
        <.link :if={request.status != :closed} navigate={~p"/approvals/#{request.id}/approve"}>
          승인
        </.link>
      </:action>

      <:action :let={{_id, request}}>
        <.link :if={request.status != :closed} navigate={~p"/approvals/#{request.id}/reject"}>
          반려
        </.link>
      </:action> --%>
    </.table>
    """
  end

  @impl true
  def handle_info({:request_updated, _updated_request}, socket) do
    # 결재 요청의 status가 업데이트되었을 때 리스트를 새로고침
    {:noreply,
     socket
     |> stream(:requests, Service.list_assignee_requests(socket.assigns.current_user),
       reset: true
     )}
  end

  def handle_info({:request_created, _created_request}, socket) do
    # 결재 요청이 새로 생성되었을 때 리스트를 새로고침
    {:noreply,
     socket
     |> stream(:requests, Service.list_assignee_requests(socket.assigns.current_user),
       reset: true
     )}
  end

  # def handle_info({ItsmWeb.EvaluationDialog, {:saved, _evaluation}}, socket) do
  #   {:noreply,
  #    socket
  #    |> stream(:requests, Service.list_assignee_requests(socket.assigns.current_user),
  #      reset: true
  #    )
  #    |> push_navigate(to: ~p"/approvals")}
  # end
end
