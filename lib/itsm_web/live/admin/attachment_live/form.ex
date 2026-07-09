defmodule ItsmWeb.Admin.AttachmentLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Attachments
  alias Itsm.Attachments.Attachment

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> ItsmWeb.LiveUtils.allow_uploads()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", _target, %{assigns: %{live_action: :new}} = socket) do
    {:noreply, socket}
  end

  def handle_event("validate", %{"attachment" => attachment_params}, socket) do
    changeset = Attachments.change_attachment(socket.assigns.attachment, attachment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"attachment" => attachment_params}, socket) do
    save_attachment(socket, socket.assigns.live_action, attachment_params)
  end

  def handle_event("save", %{}, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns

    Attachments.create_attachments(
      action_user,
      %Itsm.Attachments.Attachment{id: Ecto.UUID.autogenerate()},
      ItsmWeb.LiveUtils.build_attachment_consumer(socket)
    )

    {:noreply, socket |> push_navigate(to: "/admin/attachments")}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    attachment = %Attachment{}

    socket
    |> assign(:page_title, "New Attachment")
    |> assign(:attachment, attachment)
    |> assign_new(:form, fn -> to_form(Attachments.change_attachment(attachment)) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    attachment = Attachments.get_attachment!(id)

    socket
    |> assign(:page_title, "Edit Attachment")
    |> assign(:attachment, attachment)
    |> assign_new(:form, fn -> to_form(Attachments.change_attachment(attachment)) end)
    |> Itsm.PubSub.Helper.subscribe(Attachments, id: id, is_admin: true)
  end

  defp save_attachment(socket, :edit, attachment_params) do
    %{current_scope: %{user: action_user}, attachment: attachment} = socket.assigns

    case Attachments.update_attachment(action_user, attachment, attachment_params) do
      {:ok, _attachment} ->
        {:noreply, socket |> push_navigate(to: "/admin/attachments")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_attachment,
         %{id: id},
         %{assigns: %{attachment: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_attachment,
         %{id: id},
         %{assigns: %{attachment: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: "/admin/attachments")}
  end
end
