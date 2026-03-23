defmodule ItsmWeb.Admin.ApprovalLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Approvals
  alias Itsm.Service.Approval
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribes(:approvals)
    end

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
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
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

  defp handle_pubsub(event, _approval, socket)
       when event in [:create_approval, :update_approval] do
    {:noreply,
     socket
     |> put_flash(
       :info,
       if(event == :create_approval,
         do: gettext("Created") <> " " <> gettext("Approval"),
         else: gettext("Updated") <> " " <> gettext("Approval")
       )
     )
     |> push_patch(to: ~p"/admin/approvals?#{socket.assigns[:results][:params] || %{}}")}
  end

  defp handle_pubsub(:delete_approval, approval, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Approval"))
     |> stream_delete(:approvals, approval)}
  end
end
