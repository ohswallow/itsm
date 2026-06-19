defmodule ItsmWeb.Admin.RequestLive.Show do
  alias Itsm.Admin.Attachments
  alias Itsm.Admin.Approvals
  alias Itsm.Admin.Comments
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:attachments, []) |> stream(:comments, []) |> stream(:approvals, [])}
  end

  def handle_params(%{"id" => id}, _, socket) do
    request =
      Requests.get_request!(id)
      |> Requests.with_assoc([:category, :requestor_crew, :requestor])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:request, request)
     |> stream(:attachments, Attachments.list_attachments_by_resource(request), reset: true)
     |> stream(:comments, Comments.list_comments_by_resource(request), reset: true)
     |> stream(:approvals, Approvals.list_approvals_by_request(request), reset: true)
     |> Itsm.PubSub.Helper.subscribe(Requests, id: id, is_admin: true)}
  end

  def handle_event("delete", %{"schema" => schema, "id" => _id} = params, socket) do
    %{current_user: action_user} = socket.assigns

    case schema do
      "attachments" ->
        {:ok, attachment} = Attachments.delete_attachment(action_user, params)
        {:noreply, stream_delete(socket, :attachments, attachment)}

      "comments" ->
        {:ok, comment} = Comments.delete_comment(action_user, params)
        {:noreply, stream_delete(socket, :comments, comment)}

      "approvals" ->
        {:ok, approval} = Approvals.delete_approval(action_user, params)
        {:noreply, stream_delete(socket, :approvals, approval)}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Request"
  defp page_title(:edit), do: "Edit Request"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :request, resource_name: gettext("Request")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_request),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []
end
