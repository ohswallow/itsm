defmodule ItsmWeb.Admin.ApprovalLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals
  alias Itsm.Service.Approval
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:approvals, [])
     |> Itsm.PubSub.Helper.subscribe(Approvals, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:approvals, Approval, params, url)
     |> assign(:page_title, gettext("Listing Approvals"))}
  end

  def handle_event("delete", %{"id" => _id} = approval_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, approval} = Approvals.delete_approval(action_user, approval_params)

    {:noreply, stream_delete(socket, :approvals, approval)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [:status, :action, :approver_name],
      preloads: [request: [:title, category: :name]]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Approval"),
      target_key: :approvals,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
