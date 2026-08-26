defmodule ItsmWeb.Admin.ApprovalLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.{Approvals, Users, Requests}
  alias Itsm.Service.Approval

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign_new_options()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"approval" => approval_params}, socket) do
    changeset = Approvals.change_approval(%Approval{}, approval_params)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"approval" => approval_params}, socket) do
    save_approval(socket, socket.assigns.live_action, approval_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    approval = Approvals.get_approval!(id)

    socket
    |> assign(:page_title, gettext("Edit Approval"))
    |> assign(:approval, approval)
    |> assign_new(:form, fn -> to_form(Approvals.change_approval(approval)) end)
    |> Itsm.PubSub.Helper.subscribe(Approvals, id: id, is_admin: true)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:approver_options, fn -> Users.get_select_options() end)
    |> assign_new(:request_options, fn -> Requests.get_select_options() end)
  end

  defp save_approval(socket, :edit, approval_params) do
    %{current_scope: %{user: action_user}, approval: approval} = socket.assigns

    case Approvals.update_approval(action_user, approval, approval_params) do
      {:ok, _approval} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/approvals")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_approval,
         %{id: id},
         %{assigns: %{approval: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_approval,
         %{id: id},
         %{assigns: %{approval: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/approvals")}
  end
end
