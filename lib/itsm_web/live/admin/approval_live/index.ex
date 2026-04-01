defmodule ItsmWeb.Admin.ApprovalLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals
  alias Itsm.Service.Approval
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Approval)

    {:ok, stream(socket, :approvals, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = approval_params, socket) do
    {:ok, approval} = Approvals.delete_approval(approval_params)

    {:noreply, stream_delete(socket, :approvals, approval)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(
        params,
        url,
        Approval,
        [
          :status,
          :action,
          :approver_name
        ],
        request: [category: :name]
      )

    socket
    |> assign(:results, value.results)
    |> stream(:approvals, value.entries, reset: true)
    |> assign(:page_title, "Listing Approvals")
    |> assign(:approval, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Approval")
    |> assign(:approval, %Approval{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Approval")
    |> assign(:approval, Approvals.get_approval!(id))
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :approval,
      resource_name: gettext("Approval"),
      stream_name: :approvals,
      push_patch: [to: ~p"/admin/approvals?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
