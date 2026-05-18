defmodule ItsmWeb.Admin.AttachmentLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Attachments

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{attachment: attachment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(Attachments.change_attachment(attachment))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage attachment records in your database.</:subtitle>
      </.header>

      <div
        :if={@conflict}
        class="p-4 mb-4 bg-red-50 border border-red-200 text-red-800 rounded animate-pulse"
      >
        <div class="flex items-center gap-2 font-bold">
          <span>⚠️ 충돌 발생!</span>
        </div>
        <p class="mt-1 text-sm">{@conflict_msg}</p>
        <p class="mt-2 text-xs opacity-75">현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </div>

      <.simple_form
        for={@form}
        id="attachment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:filename]} type="text" label={gettext("Filename")} />
        <.input field={@form[:local_path]} type="text" label={gettext("Local Path")} />
        <.input field={@form[:file_type]} type="text" label={gettext("File Type")} />
        <.input field={@form[:byte_size]} type="number" label={gettext("Byte Size")} />
        <.input field={@form[:status]} type="text" label={gettext("Status")} />
        <.input field={@form[:resource_type]} type="text" label={gettext("Resource Type")} />
        <.input field={@form[:resource_id]} type="text" label={gettext("Resource Id")} />
        <.itsm_calendar
          field={@form[:deleted_at]}
          label={gettext("Deleted At")}
          show_time
          default_selected_date_time={@form[:deleted_at].value}
        />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Attachment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"attachment" => attachment_params}, socket) do
    changeset = Attachments.change_attachment(socket.assigns.attachment, attachment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"attachment" => attachment_params}, socket) do
    save_attachment(socket, socket.assigns.action, attachment_params)
  end

  defp save_attachment(socket, :edit, attachment_params) do
    %{current_user: action_user, attachment: attachment} = socket.assigns

    case Attachments.update_attachment(action_user, attachment, attachment_params) do
      {:ok, _attachment} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_attachment(socket, :new, attachment_params) do
    %{current_user: action_user} = socket.assigns

    case Attachments.create_attachment(action_user, attachment_params) do
      {:ok, _attachment} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

end
