defmodule ItsmWeb.Admin.CommonCodeLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes
  alias Itsm.Common.CommonCode

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"common_code" => common_code_params}, socket) do
    changeset = CommonCodes.change_common_code(%CommonCode{}, common_code_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"common_code" => common_code_params}, socket) do
    save_common_code(socket, socket.assigns.live_action, common_code_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, gettext("New CommonCode"))
    |> assign(:common_code, %CommonCode{})
    |> assign_new(:form, fn -> to_form(CommonCodes.change_common_code(%CommonCode{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    common_code = CommonCodes.get_common_code!(id)

    socket
    |> assign(:page_title, gettext("Edit CommonCode"))
    |> assign(:common_code, common_code)
    |> assign_new(:form, fn -> to_form(CommonCodes.change_common_code(common_code)) end)
    |> Itsm.PubSub.Helper.subscribe(CommonCodes, id: id, is_admin: true)
  end

  defp save_common_code(socket, :edit, common_code_params) do
    %{current_scope: %{user: action_user}, common_code: common_code} = socket.assigns

    case CommonCodes.update_common_code(action_user, common_code, common_code_params) do
      {:ok, _common_code} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/common-codes")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_common_code(socket, :new, common_code_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case CommonCodes.create_common_code(action_user, common_code_params) do
      {:ok, _common_code} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/common-codes")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_common_code,
         %{id: id},
         %{assigns: %{common_code: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_common_code,
         %{id: id},
         %{assigns: %{common_code: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/common-codes")}
  end
end
