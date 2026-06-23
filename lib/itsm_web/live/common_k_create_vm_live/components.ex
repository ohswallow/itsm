defmodule ItsmWeb.CommonKCreateVmLive.Components do
  use ItsmWeb, :html

  alias Itsm.Workflow
  alias ItsmWeb.CustomComponents

  def request_header(assigns) do
    ~H"""
    <div class="border-b-2 border-zinc-200 pb-4 mb-4">
      <.header>
        {@request.category.name}
        <:subtitle>Request ID: {@request.id}</:subtitle>

        <.link
          :if={@show_edit}
          navigate={~p"/common_k_create_vm/#{@request}/edit"}
          class="text-sm text-zinc-700"
        >
          Edit
        </.link>

        <.link navigate={~p"/common_k_create_vm/#{@request}/copy"} class="text-sm text-zinc-700">
          Copy
        </.link>
      </.header>
    </div>
    """
  end

  def request_info(assigns) do
    ~H"""
    <.list>
      <:item title={gettext("Title")}>{@request.title}</:item>

      <:item title={gettext("Description")}>{@request.description}</:item>

      <:item title={gettext("Environment")}>
        <.common_code_label group="운영_구분" code={@request.env} />
      </:item>

      <:item title={gettext("Status")}>{Workflow.status_label(:service_request, @request)}</:item>

      <:item title={gettext("Due Date")}>
        <div
          id={"due_date_#{@request.id}"}
          phx-hook="LocalTime.ToLocale"
          format="datetime"
          utc-value={@request.due_date}
        />
      </:item>

      <:item title="Referenced Crew">
        <div class="flex flex-wrap items-center gap-3">
          <CustomComponents.crew_tooltip :for={%{crew: crew} <- @request.crew_references} crew={crew} />
        </div>
      </:item>
    </.list>
    """
  end

  def vm_section(assigns) do
    ~H"""
    <div class="mt-8">
      <h2 class="text-lg font-semibold text-zinc-700 mb-4">VM 생성 요청</h2>

      <div class="space-y-4">
        <div
          :for={{vm, index} <- Enum.with_index(@vms, 1)}
          class="border border-zinc-200 rounded-lg p-4"
        >
          <h3 class="font-semibold text-zinc-800 mb-3">VM #{index}</h3>

          <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-2">
            <div>
              <dt class="text-sm font-medium text-zinc-500">호스트명</dt>

              <dd class="text-sm text-zinc-900">{vm.hostname}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">서비스명</dt>

              <dd class="text-sm text-zinc-900">{vm.service_name}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">OS 종류</dt>

              <dd class="text-sm text-zinc-900">{vm.os_image}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">OS 버전</dt>

              <dd class="text-sm text-zinc-900">{vm.os_version}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">CPU(vCore)</dt>

              <dd class="text-sm text-zinc-900">{vm.cpu}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">Memory(GB)</dt>

              <dd class="text-sm text-zinc-900">{vm.memory}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">{gettext("Location")}</dt>

              <dd class="text-sm text-zinc-900">{vm.location}</dd>
            </div>

            <div>
              <dt class="text-sm font-medium text-zinc-500">{gettext("Is DMZ?")}</dt>

              <dd class="text-sm text-zinc-900">{vm.is_dmz_zone}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :attachments_count, :integer, required: true
  slot :inner_block, required: true

  def attachments_section(assigns) do
    ~H"""
    <div class="mt-8">
      <h2 class="text-lg font-semibold text-zinc-700 mb-4">첨부파일 ({@attachments_count})</h2>

      <div id={@id} class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4" phx-update="stream">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :attachment, :any, required: true, doc: "%Itsm.Attachments.attachment{}"
  attr :live_action, :atom, default: :view
  attr :target, :any, default: nil

  def attachment(assigns) do
    ~H"""
    <div id={@id} class="relative group">
      <div
        class="group relative border border-zinc-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
        phx-click="view_attachment"
        phx-value-filename={@attachment.filename}
        phx-value-id={@attachment.id}
      >
        <div class="aspect-square bg-zinc-100">
          <img
            src={~p"/attachments/download/#{@attachment.id}"}
            alt={@attachment.filename}
            class="w-full h-full object-cover"
          />
        </div>

        <div class="p-2 bg-white">
          <p class="text-xs text-zinc-700 truncate">{@attachment.filename}</p>

          <p class="text-xs text-zinc-400">{format_file_size(@attachment.byte_size)}</p>
        </div>

        <div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
          <.icon name="hero-magnifying-glass-plus" class="w-8 h-8 text-white" />
        </div>
      </div>

      <.button
        :if={@live_action == :edit}
        class="top-2 right-2 p-1 bg-white/80 rounded-full opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-50"
        phx-click="delete_attachment"
        phx-value-id={@attachment.id}
        phx-target={@target}
        data-confirm="정말로 이 첨부파일을 삭제하시겠습니까?"
      >
        <.icon name="hero-x-mark" class="w-6 h-6 text-red-600" />
      </.button>
    </div>
    """
  end

  def comments_section(assigns) do
    ~H"""
    <div class="mt-8 bg-white rounded-lg shadow-sm border border-slate-200 p-6">
      <div class="text-lg font-semibold text-slate-900 mb-4">Activity & Comments</div>

      <div id="comments" phx-update="stream">
        <.comment_item :for={{dom_id, comment} <- @streams.comments} comment={comment} id={dom_id} />
      </div>
    </div>
    """
  end

  def comment_item(assigns) do
    ~H"""
    <div class="space-y-4 mb-6" id={@id}>
      <div class="flex-1">
        <div class="flex items-center gap-2 mb-1">
          <span class="font-semibold text-slate-900">{@comment.user.display_name}</span>
          <span
            id={"comment-#{@id}-timestamp"}
            class="text-xs text-slate-500"
            phx-hook="LocalTime.ToLocale"
            utc-value={@comment.inserted_at}
          ></span>
        </div>

        <div class="bg-slate-50 rounded-lg p-3">
          <p class="text-sm text-slate-700 whitespace-pre-wrap">{@comment.comment}</p>

          <div :if={Enum.any?(@comment.attachments)} class="mt-3 pt-2 border-t border-slate-200">
            <p class="text-xs text-slate-400 mb-2 font-medium">Attachments</p>

            <div class="flex flex-wrap gap-2">
              <div
                :for={attachment <- @comment.attachments}
                phx-click="view_attachment"
                phx-value-filename={attachment.filename}
                phx-value-id={attachment.id}
                class="group flex items-center gap-2 bg-white border border-slate-200 rounded px-2 py-1.5 hover:border-blue-400 hover:shadow-sm transition-all cursor-pointer"
              >
                <div class="bg-blue-50 text-blue-600 rounded p-0.5">
                  <.icon name="hero-paper-clip" class="w-3 h-3" />
                </div>

                <span class="text-xs text-slate-600 group-hover:text-blue-600 max-w-[158px] truncate">
                  {attachment.filename}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def comment_form(assigns) do
    ~H"""
    <.form for={@form} id="comment-form" phx-change="validate" phx-submit="save" class="mt-4">
      <.input field={@form[:comment]} type="textarea" placeholder="Comment..." />
      <div class="flex items-center justify-between py-2 px-3 border border-t-0 border-zinc-300 bg-zinc-50 rounded-b-lg">
        <div class="flex items-center gap-2">
          <label class="cursor-pointer inline-flex items-center gap-1 text-zinc-500 hover:text-blue-600 transition-colors p-1.5 rounded-md hover:bg-zinc-200">
            <.live_file_input upload={@uploads.attachment} class="hidden" />
            <.icon name="hero-arrow-up-on-square" class="w-5 h-5" />
            <span class="text-xs font-medium">파일 업로드</span>
          </label>

          <span
            :if={length(@uploads.attachment.entries) > 0}
            class="text-xs text-blue-600 font-semibold"
          >
            {length(@uploads.attachment.entries)}개 선택됨
          </span>
        </div>
        <.button phx-disable-with="Saving..." class="text-xs px-3 py-1.5">Add Comment</.button>
      </div>

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
            class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-md hover:bg-red-600"
          >
            <.icon name="hero-x-mark" class="w-3 h-3" />
          </button>

          <p
            :for={err <- upload_errors(@uploads.attachment, entry)}
            class="mt-1.5 flex gap-2 items-center text-sm text-error"
          >
            <.icon name="hero-exclamation-circle" class="size-5" /> {Phoenix.Naming.humanize(err)}
          </p>
        </div>
      </div>
    </.form>
    """
  end

  def attachment_modal(assigns) do
    ~H"""
    <.modal id="attachment-modal" show on_cancel={JS.push("close_attachment")}>
      <div class="text-center">
        <img
          src={~p"/attachments/download/#{@attachment.id}"}
          alt={@attachment.filename}
          class="max-h-[70vh] mx-auto rounded-lg"
        />
        <div class="mt-4 flex items-center justify-center gap-4">
          <span class="text-sm text-zinc-600">{@attachment.filename}</span>
          <a
            href={~p"/attachments/download/#{@attachment.id}"}
            download={@attachment.filename}
            class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
          >
            <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> 다운로드
          </a>
        </div>
      </div>
    </.modal>
    """
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
