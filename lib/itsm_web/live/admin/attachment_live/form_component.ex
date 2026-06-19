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
     |> ItsmWeb.LiveUtils.allow_uploads()
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

      <.form
        for={@form}
        id="attachment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <fragment :if={@action == :edit}>
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
        </fragment>

        <fragment :if={@action == :new}>
          <div
            :if={Enum.any?(@uploads.attachment.entries)}
            class="mt-3 pt-2"
          >
            <p class="text-xs text-slate-400 mb-2 font-medium">Attachments</p>

            <div class="flex flex-wrap gap-2">
              <div
                :for={attachment <- @uploads.attachment.entries}
                class="group flex items-center gap-2 bg-white border border-slate-200 rounded px-2 py-1.5 hover:border-blue-400 hover:shadow-sm transition-all cursor-pointer"
              >
                <div class="bg-blue-50 text-blue-600 rounded p-0.5">
                  <.icon name="hero-paper-clip" class="w-3 h-3" />
                </div>

                <span class="text-xs text-slate-600 group-hover:text-blue-600 max-w-[158px] truncate">
                  {attachment.client_name}
                </span>
              </div>
            </div>
          </div>
          <%!-- 파일업로드 --%>
          <label class="block text-sm font-semibold text-zinc-700 mb-2">
            {gettext("Attachments")}
          </label>
          <.live_file_input class="hidden" upload={@uploads.attachment} />
          <label
            class="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 mt-2"
            for={@uploads.attachment.ref}
            phx-drop-target={@uploads.attachment.ref}
          >
            <div class="flex flex-col items-center justify-center pt-5 pb-6">
              <.icon name="hero-arrow-up-tray" class="w-8 h-8 mb-4 text-gray-500" />
              <p class="mb-2 text-sm text-gray-500">
                <spaxn class="font-semibold">Click to upload</spaxn>
                or drag and drop
              </p>

              <p class="text-xs text-gray-500">
                {@uploads.attachment.max_entries} photos max, up to {trunc(
                  @uploads.attachment.max_file_size / (1 * 1024 * 1024)
                )} MB each
              </p>
            </div>
          </label>

          <p
            :for={err <- upload_errors(@uploads.attachment)}
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" /> {Phoenix.Naming.humanize(err)}
          </p>
        </fragment>

        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Attachment</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  def handle_event(
        "validate",
        _target,
        %{assigns: %{action: :new}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_event("validate", %{"attachment" => attachment_params}, socket) do
    changeset = Attachments.change_attachment(socket.assigns.attachment, attachment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"attachment" => attachment_params}, socket) do
    save_attachment(socket, socket.assigns.action, attachment_params)
  end

  def handle_event("save", %{}, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns

    Attachments.create_attachments(
      action_user,
      %Itsm.Attachments.Attachment{id: Ecto.UUID.autogenerate()},
      ItsmWeb.LiveUtils.build_attachment_consumer(socket)
    )

    {:noreply, socket |> push_patch(to: socket.assigns.patch)}
  end

  defp save_attachment(socket, :edit, attachment_params) do
    %{current_scope: %{user: action_user}, attachment: attachment} = socket.assigns

    case Attachments.update_attachment(action_user, attachment, attachment_params) do
      {:ok, _attachment} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
