defmodule ItsmWeb.PostLive.FormComponent do
  use ItsmWeb, :live_component

  import ItsmWeb.CommonKCreateVmLive.Components
  alias Itsm.Posts

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{post: post, board_id: board_id} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> ItsmWeb.LiveUtils.allow_uploads()
     |> assign(:conflict, false)
     |> assign_new_options()
     |> apply_action(board_id, post, assigns.action)}
  end

  defp apply_action(socket, _board_id, post, :edit) do
    selected_board = Itsm.Boards.get_board!(post.board_id)
    attachments = Itsm.Attachments.get_list_attachments(post)
    post = Map.put(post, :board_id, selected_board.id)

    socket
    |> assign(:attachments_count, length(attachments))
    |> stream(:form_attachments, attachments, reset: true)
    |> assign(:selected_board, selected_board)
    |> assign_new(:form, fn ->
      to_form(Posts.change_post(post))
    end)
  end

  defp apply_action(socket, board_id, post, _action) do
    socket
    |> assign(:selected_board, board_id && Itsm.Boards.get_board!(board_id))
    |> assign_new(:form, fn ->
      to_form(Posts.change_post(post))
    end)
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {assigns[:board_name] || "Not Found"} {@title}
        <:subtitle>Use this form to manage post records in your database.</:subtitle>
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

      <.form>
        for={@form} id="post-form"
        phx-target={@myself} phx-change="validate"
        phx-submit="save"
        >
        <.input
          field={@form[:title]}
          type="text"
          label={gettext("Title")}
        /> <.input field={@form[:content]} type="textarea" label={gettext("Content")} />
        <div
          :if={assigns[:selected_board] && Map.get(@selected_board, :metadata, %{})["fields"]}
          class="space-y-4"
        >
          <fragment :for={field <- @selected_board.metadata["fields"] || []}>
            <.input
              :if={field && field["type"] !== "date"}
              field={
                ItsmWeb.LiveUtils.get_sub_field(
                  field["name"],
                  @form[:metadata],
                  @form.params["metadata"],
                  field["default"]
                )
              }
              type={field["type"]}
              label={field["label"]}
              autocomplete={if field["type"] == "password", do: "new-password", else: "one-time-code"}
              options={Map.get(field, "options", [])}
            />
            <.itsm_calendar
              :if={field && field["type"] === "date"}
              field={
                ItsmWeb.LiveUtils.get_sub_field(
                  field["name"],
                  @form[:metadata],
                  @form.params["metadata"],
                  field["default"]
                )
              }
              label={field["label"]}
              show_time
              default_selected_date_time={
                @form[:metadata].value != [""] && @form[:metadata].value[field["name"]]
              }
              rests={%{hour: %{name: ""}, minute: %{name: ""}}}
            /> <br />
          </fragment>

          <fragment :if={@selected_board.metadata && @selected_board.metadata["is_attachments"]}>
            <.attachments_section
              :if={@action == :edit and @attachments_count > 0}
              id="form-attachments"
              attachments_count={@attachments_count}
            >
              <.attachment
                :for={{dom_id, attachment} <- @streams.form_attachments}
                id={dom_id}
                attachment={attachment}
                live_action={@action}
                target={@myself}
              />
            </.attachments_section>
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

            <div
              :if={length(@uploads.attachment.entries) > 0}
              class="mt-3 grid grid-cols-2 sm:grid-cols-4 gap-4"
            >
              <div
                :for={entry <- @uploads.attachment.entries}
                class="relative group border border-zinc-200 rounded-lg p-2 bg-white shadow-sm"
              >
                <div class="aspect-square bg-zinc-100 rounded-md overflow-hidden mb-2">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                </div>

                <p class="text-xs text-zinc-600 truncate px-1">{entry.client_name}</p>

                <p class="text-xs text-zinc-400">{format_file_size(entry.client_size)}</p>

                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-md hover:bg-red-600 transition-colors"
                >
                  <.icon name="hero-x-mark" class="w-3 h-3" />
                </button>

                <p
                  :for={err <- upload_errors(@uploads.attachment, entry)}
                  class="mt-1.5 flex gap-2 items-center text-sm text-error"
                >
                  <.icon name="hero-exclamation-circle" class="size-5" /> {Phoenix.Naming.humanize(
                    err
                  )}
                </p>
              </div>
            </div>
          </fragment>
        </div>

        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Post</.button>
        </:actions>

        <p
          :for={{msg, opts} <- Map.get(@form[:board_id], :errors) || []}
          class="mt-1.5 flex gap-2 items-center text-sm text-error"
        >
          <.icon name="hero-exclamation-circle" class="size-5" /> Board {translate_error({msg, opts})}
        </p>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns
    selected_board = Itsm.Boards.get_board!(socket.assigns[:board_id] || post_params["board_id"])
    post = Map.put(post, :board_id, selected_board.id)

    changeset =
      Posts.change_post(
        post,
        action_user: action_user,
        attrs: post_params,
        selected_board_metadata: Map.get(selected_board, :metadata, %{})
      )

    {:noreply,
     socket
     |> assign(:selected_board, selected_board)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    selected_board = Itsm.Boards.get_board!(socket.assigns.board_id)
    post_params = Map.put(post_params, "board_id", selected_board.id)

    save_post(
      socket,
      socket.assigns.action,
      post_params,
      Map.get(selected_board, :metadata, %{})
    )
  end

  def handle_event("delete_attachment", %{"id" => id}, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Itsm.Attachments.delete_attachment(action_user, id) do
      {:ok, attachment} ->
        {:noreply, stream_delete(socket, :form_attachments, attachment)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete attachment.")}
    end
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:board_options, fn -> Itsm.Boards.get_select_options() end)
    |> assign_new(:author_options, fn -> Itsm.Accounts.get_select_options() end)
  end

  defp save_post(
         %{assigns: %{uploads: %{attachment: %{entries: [_ | _]}}}} = socket,
         action,
         post_params,
         selected_board_metadata
       ) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns

    case Posts.save_with_attachment(
           action,
           action_user,
           post || %{},
           post_params,
           selected_board_metadata,
           ItsmWeb.LiveUtils.build_attachment_consumer(socket)
         ) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :edit, post_params, selected_board_metadata) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns

    case Posts.update_post(action_user, post, post_params, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, selected_board_metadata) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Posts.create_post(action_user, post_params, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
