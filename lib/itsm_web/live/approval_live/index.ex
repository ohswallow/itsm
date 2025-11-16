defmodule ItsmWeb.ApprovalLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Service
  alias Itsm.Service.Approval

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :approvals, Service.list_approvals())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Approval")
    |> assign(:approval, Service.get_approval!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Approval")
    |> assign(:approval, %Approval{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Approvals")
    |> assign(:approval, nil)
  end

  @impl true
  def handle_info({ItsmWeb.ApprovalLive.FormComponent, {:saved, approval}}, socket) do
    {:noreply, stream_insert(socket, :approvals, approval)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    approval = Service.get_approval!(id)
    {:ok, _} = Service.delete_approval(approval)

    {:noreply, stream_delete(socket, :approvals, approval)}
  end
end
