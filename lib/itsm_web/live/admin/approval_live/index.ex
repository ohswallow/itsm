defmodule ItsmWeb.Admin.ApprovalLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals
  alias Itsm.Service.Approval
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :approvals, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    approval = Approvals.get_approval!(id)
    {:ok, _} = Approvals.delete_approval(approval)

    {:noreply, stream_delete(socket, :approvals, approval)}
  end

  @impl true
  def handle_info({ItsmWeb.Admin.ApprovalLive.FormComponent, {:saved, approval}}, socket) do
    {:noreply, stream_insert(socket, :approvals, approval)}
  end

  defp apply_action(socket, :index, params, url) do
    results =
      Paging.search_and_pagination(
        params,
        url,
        Approval,
        [
          :status,
          :action,
          :approver_name
        ],
        request: :category
      )

    socket
    |> assign(:results, results)
    |> stream(:approvals, results.entries, reset: true)
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
end
