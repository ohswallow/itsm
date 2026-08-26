defmodule ItsmWeb.ApprovalLive.Index do
  use ItsmWeb, :live_view

  import ItsmWeb.ApprovalLive.Components

  alias Phoenix.LiveView.JS
  alias Itsm.Requests
  alias Itsm.Crews
  alias Itsm.Approvals
  alias Itsm.Workflow

  def mount(_params, _session, socket) do
    {:ok,
     initial_page(socket)
     |> assign(:page_title, "Listing Approvals")
     |> Itsm.PubSub.Helper.subscribe(Crews)
     |> Itsm.PubSub.Helper.subscribe(Requests)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_info(
        {ItsmWeb.CreateCommentDialog, {_event, %{request: request, approval: approval}}},
        socket
      ) do
    %{current_scope: %{user: current_user}, my_crew_ids: my_crew_ids} = socket.assigns

    my_crew? = request.requestor_crew_id in my_crew_ids
    stream_where_requests(socket, request, approval, current_user, my_crew?)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp initial_page(socket) do
    %{current_scope: %{user: current_user}} = socket.assigns

    my_crews_ids = Crews.list_my_crews_ids(current_user)

    Enum.reduce(my_crews_ids, socket, fn crew_id, acc_socket ->
      Itsm.PubSub.Helper.subscribe(acc_socket, Crews, id: crew_id, only: :detail)
    end)
    |> unsubscribe_my_crews(my_crews_ids)
    |> assign(:my_crew_ids, my_crews_ids)
    |> stream(:requests, Approvals.list_pending_requests(current_user), reset: true)
  end

  defp unsubscribe_my_crews(
         %{assigns: %{my_crew_ids: previous_my_crew_ids}} = socket,
         my_crews_ids
       ) do
    Enum.reduce(previous_my_crew_ids -- my_crews_ids, socket, fn crew_id, acc_socket ->
      Itsm.PubSub.Helper.unsubscribe(acc_socket, Crews, id: crew_id, only: :detail)
    end)
  end

  defp unsubscribe_my_crews(socket, _my_crews_ids), do: socket

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

  defp apply_action(socket, :index, _params), do: socket

  defp handle_pubsub(_action_user, event, _item, socket)
       when event in [:update_crew, :delete_crew, :add_crews_users, :delete_crews_users] do
    {:noreply, initial_page(socket)}
  end

  defp handle_pubsub(action_user, :create_request = event, request, socket) do
    %{current_scope: %{user: current_user}, my_crew_ids: my_crew_ids} = socket.assigns

    my_crew? = request.requestor_crew_id in my_crew_ids
    opts = [resource_name: gettext("Approval")]

    socket
    |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, request, opts)
    |> stream_where_requests(request, nil, current_user, my_crew?)
  end

  defp handle_pubsub(action_user, :update_request = event, {request, approval}, socket) do
    %{current_scope: %{user: current_user}, my_crew_ids: my_crew_ids} = socket.assigns

    my_crew? = request.requestor_crew_id in my_crew_ids

    opts = [resource_name: gettext("Approval")]

    socket
    |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, request, opts)
    |> stream_where_requests(request, approval, current_user, my_crew?)
  end

  defp handle_pubsub(_action_user, _event, _item, socket), do: {:noreply, socket}

  defp stream_where_requests(
         socket,
         request,
         _approval,
         _current_user,
         _my_crew?
       )
       when request.status in [:closed, :rejected] do
    {:noreply, stream_delete(socket, :requests, request)}
  end

  defp stream_where_requests(
         socket,
         request,
         _approval,
         current_user,
         my_crew?
       )
       when request.status == :validation and request.requestor_id != current_user.id and my_crew? do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  defp stream_where_requests(
         socket,
         request,
         _approval,
         _current_user,
         my_crew?
       )
       when request.status in [:assignment, :start, :finish] and my_crew? do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  defp stream_where_requests(
         socket,
         request,
         approval,
         current_user,
         my_crew?
       )
       when request.status == :check and approval.approver_id != current_user.id and my_crew? do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  defp stream_where_requests(
         socket,
         request,
         _approval,
         current_user,
         _my_crew?
       )
       when request.status == :confirmation and request.requestor_id == current_user.id do
    {:noreply, stream_insert(socket, :requests, request)}
  end

  defp stream_where_requests(
         socket,
         request,
         _approval,
         _current_user,
         _my_crew?
       ) do
    {:noreply, stream_delete(socket, :requests, request)}
  end
end
