defmodule ItsmWeb.CommonKCreateVmLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Service
  alias Itsm.Comments
  alias Itsm.Comments.Comment

  on_mount {ItsmWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    changeset = Comments.change_comment(%Comment{})
    # socket = assign(socket, :form, to_form(changeset))
    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> allow_upload(:attachment,
       accept: ~w(.png .jpg .jpeg .bmp .gif),
       max_entries: 4,
       max_file_size: 1 * 1024 * 1024
     )}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      Service.subscribe_request(id)
    end

    request = Service.get_request!(id)
    comments = Service.list_comments(request)

    {
      :noreply,
      socket
      |> assign(:page_title, "Show Request")
      |> assign(:request, request)
      |> stream(:comments, comments)
      # 모달용
      |> assign(:selected_attachment, nil)
      #  |> assign(:workflow_steps, Approval.status_values())
    }
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-6">
      <!-- 메인 컨텐츠 영역 -->
      <div class="flex-1">
        <div class="border-b-2 border-zinc-200 pb-4 mb-4">
          <.header>
            {@request.title}
            <:subtitle>Request ID: {@request.id}</:subtitle>
            
            <:actions>
              <.link
                navigate={~p"/common_k_create_vm/#{@request}/edit"}
                class="text-sm text-zinc-700"
              >
                Edit
              </.link>
              <.link
                navigate={~p"/common_k_create_vm/#{@request}/copy"}
                class="text-sm text-zinc-700"
              >
                Copy
              </.link>
            </:actions>
          </.header>
        </div>
        
        <.list>
          <:item title="Title">{@request.title}</:item>
          
          <:item title="Description">{@request.description}</:item>
          
          <:item title="Environment">{@request.env}</:item>
          
          <:item title="Status">{@request.status}</:item>
          
          <:item title="Due Date"><.local_time id="due_date" at={@request.due_date} /></:item>
          
          <:item title="Requestor">{@request.requestor_name} ({@request.requestor_id})</:item>
          
          <:item title="Assignee">{@request.assignee_name} ({@request.assignee_id})</:item>
          
          <:item title="Category">{@request.category.name}</:item>
        </.list>
        
        <div :if={Enum.any?(@request.common_k_create_vms)} class="mt-8">
          <h2 class="text-lg font-semibold text-zinc-700 mb-4">VM 생성 요청</h2>
          
          <div class="space-y-4">
            <div
              :for={{vm, index} <- Enum.with_index(@request.common_k_create_vms, 1)}
              class="border border-zinc-200 rounded-lg p-4"
            >
              <h3 class="font-semibold text-zinc-800 mb-3">VM #{index}</h3>
              
              <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-2">
                <div>
                  <dt class="text-sm font-medium text-zinc-500">호스트명</dt>
                  
                  <dd class="text-sm text-zinc-900">{vm.hostname}</dd>
                </div>
                
                <div>
                  <dt class="text-sm font-medium text-zinc-500">서버 설명</dt>
                  
                  <dd class="text-sm text-zinc-900">{vm.description}</dd>
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
                  <dt class="text-sm font-medium text-zinc-500">CPU/메모리</dt>
                  
                  <dd class="text-sm text-zinc-900">{vm.cpu_memory}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </div>
      <!-- 워크플로우 사이드바 -->
      <%!-- <div class="w-80 flex-shrink-0">
        <div class="sticky top-4 bg-white rounded-xl shadow-lg border border-gray-100 p-6">
          <!-- 헤더 -->
          <div class="text-center mb-6 pb-4 border-b-2 border-gray-100">
            <h2 class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              Progress
            </h2>
          </div>
          <!-- 워크플로우 스텝들 -->
          <div class="space-y-3">
            <div
              :for={step <- @workflow_steps}
              class={[
                "flex items-center justify-between py-2 px-3 rounded-lg transition-colors",
                if(@request.status == step,
                  do: "bg-red-50 border-2 border-red-500 py-3 animate-pulse",
                  else: "hover:bg-gray-50 opacity-60"
                )
              ]}
            >
              <div class="flex items-center gap-3">
                <span class={[
                  "font-semibold",
                  if(@request.status == step,
                    do: "text-base text-red-600 font-bold",
                    else: "text-sm text-gray-500"
                  )
                ]}>
                  {String.capitalize(Atom.to_string(step))}
                </span>
                <span :if={@request.status == step} class="text-xs text-red-500 font-semibold">
                  ● 진행중
                </span>
              </div>

              <div class="text-xs text-gray-400">-</div>
            </div>
          </div>
          <!-- 진행도 바 -->
          <div class="mt-6 pt-4 border-t border-gray-100">
            <div class="flex items-center justify-between text-xs text-gray-500 mb-2">
              <span>진행률</span> <span class="font-semibold">2/7 단계</span>
            </div>

            <div class="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
              <div
                class="bg-gradient-to-r from-blue-500 to-red-500 h-full rounded-full transition-all duration-500"
                style="width: 28.5%"
              >
              </div>
            </div>
          </div>
        </div>
      </div> --%>
    </div>
     <%!-- 첨부파일 섹션 --%>
    <div :if={Enum.any?(@request.attachments)} class="mt-8">
      <h2 class="text-lg font-semibold text-zinc-700 mb-4">첨부파일 ({length(@request.attachments)})</h2>
      
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        <div
          :for={attachment <- @request.attachments}
          class="group relative border border-zinc-200 rounded-lg overflow-hidden hover:shadow-md transition-shadow cursor-pointer"
          phx-click="view_attachment"
          phx-value-url={attachment.local_path}
          phx-value-filename={attachment.filename}
          phx-value-id={attachment.id}
        >
          <%!-- 썸네일 --%>
          <div class="aspect-square bg-zinc-100 flex items-center justify-center">
            <img
              src={attachment.local_path}
              alt={attachment.filename}
              class="w-full h-full object-cover"
            />
          </div>
           <%!-- 파일 정보 --%>
          <div class="p-2 bg-white">
            <p class="text-xs text-zinc-700 truncate" title={attachment.filename}>
              {attachment.filename}
            </p>
            
            <p class="text-xs text-zinc-400">{format_file_size(attachment.byte_size)}</p>
          </div>
           <%!-- 호버 시 오버레이 --%>
          <div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
            <.icon name="hero-magnifying-glass-plus" class="w-8 h-8 text-white" />
          </div>
        </div>
      </div>
    </div>
     <%!-- 첨부파일 확대 모달 --%>
    <.modal
      :if={@selected_attachment}
      id="attachment-modal"
      show
      on_cancel={JS.push("close_attachment")}
    >
      <div class="text-center">
        <img
          src={@selected_attachment.local_path}
          alt={@selected_attachment.filename}
          class="max-h-[70vh] mx-auto rounded-lg"
        />
        <div class="mt-4 flex items-center justify-center gap-4">
          <span class="text-sm text-zinc-600">{@selected_attachment.filename}</span>
          <a
            href={@selected_attachment.local_path}
            download={@selected_attachment.filename}
            class="inline-flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800"
          >
            <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> 다운로드
          </a>
        </div>
      </div>
    </.modal>

    <div class="mt-4 bg-white rounded-lg shadow-sm border border-slate-200 p-6">
      <div class="text-lg font-semibold text-slate-900 mb-4">Activity & Comments</div>
      
      <div id="comments" phx-update="stream">
        <.comment_list :for={{dom_id, comment} <- @streams.comments} comment={comment} id={dom_id} />
      </div>
    </div>

    <div :if={@request.status != :closed}>
      <.comment_form
        form={@form}
        uploads={@uploads}
      />
    </div>

    <.back navigate={~p"/requests"}>Back</.back>
    """
  end

  attr :id, :string, required: true
  attr :comment, Comment, required: true

  def comment_list(assigns) do
    ~H"""
    <div class="space-y-4 mb-6" id={@id}>
      <div class="flex-1">
        <div class="flex items-center gap-2 mb-1">
          <span class="font-semibold text-slate-900">{@comment.user.display_name}</span>
          <span class="text-xs text-slate-500">{@comment.inserted_at}</span>
        </div>
        
        <div class="bg-slate-50 rounded-lg p-3">
          <p class="text-sm text-slate-700 whitespace-pre-wrap">{@comment.comment}</p>
          
          <div :if={Enum.any?(@comment.attachments)} class="mt-3 pt-2 border-t border-slate-200">
            <p class="text-xs text-slate-400 mb-2 font-medium">Attachments</p>
            
            <div class="flex flex-wrap gap-2">
              <div
                :for={attachment <- @comment.attachments}
                phx-click="view_attachment"
                phx-value-url={attachment.local_path}
                phx-value-filename={attachment.filename}
                class="group flex items-center gap-2 bg-white border border-slate-200 rounded px-2 py-1.5 hover:border-blue-400 hover:shadow-sm transition-all cursor-pointer"
              >
                <div class="bg-blue-50 text-blue-600 rounded p-0.5">
                  <.icon name="hero-paper-clip" class="w-3 h-3" />
                </div>
                
                <span class="text-xs text-slate-600 group-hover:text-blue-600 max-w-[200px] truncate">
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
    <.form for={@form} id="comment-form" phx-change="validate" phx-submit="save" class="relative">
      <%!-- <div class="bg-white border border-zinc-300 rounded-lg shadow-sm focus-within:ring-1 focus-within:ring-blue-500 focus-within:border-blue-500"> --%>
      <.input
        field={@form[:comment]}
        type="textarea"
        placeholder="Comment..."
      />
      <%!-- <div class="flex items-center justify-between py-2 px-3 border-t border-zinc-100 bg-zinc-50 rounded-b-lg"> --%>
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
       <%!-- </div> --%> <%!-- 업로드 파일이  max_entries 이상일때 에러 표시  --%>
      <.error :for={err <- upload_errors(@uploads.attachment)}>{Phoenix.Naming.humanize(err)}</.error>
      
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
          
          <%!-- 파일업로드 진행률을 위한 bar인데, 대용량일 경우 필요함. 지금 현재 기준(1MB)는 너무 빨라서 보이지 않음. --%>
          <%!-- <div class="w-full bg-gray-200 rounded-full h-1 mt-2">
              <div
                class="bg-blue-600 h-1 rounded-full transition-all duration-300"
                style={"width: #{entry.progress}%"}
              >
              </div>
            </div> --%>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center shadow-md hover:bg-red-600 transition-colors"
          >
            <.icon name="hero-x-mark" class="w-3 h-3" />
          </button>
          <.error :for={err <- upload_errors(@uploads.attachment, entry)}>
            {Phoenix.Naming.humanize(err)}
          </.error>
        </div>
      </div>
    </.form>
    """
  end

  # 댓글 첨부파일 클릭 시 모달 띄우기 (DB 조회 없이 URL 사용)
  def handle_event("view_attachment", %{"url" => url, "filename" => filename}, socket) do
    attachment = %{local_path: url, filename: filename}

    {:noreply, assign(socket, :selected_attachment, attachment)}
  end

  # # 모달 열기/닫기 이벤트
  # def handle_event("view_attachment", %{"id" => id}, socket) do
  #   attachment = Enum.find(socket.assigns.request.attachments, &(&1.id == id))
  #   {:noreply, assign(socket, :selected_attachment, attachment)}
  # end

  def handle_event("close_attachment", _, socket) do
    {:noreply, assign(socket, :selected_attachment, nil)}
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    IO.inspect(socket.assigns.streams.comments, label: "Comments in Validate")
    changeset = Comments.change_comment(%Comment{}, comment_params)

    socket = assign(socket, :form, to_form(changeset, action: :validate))

    {:noreply, socket}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    %{request: request, current_user: current_user} = socket.assigns

    # 1. 업로드된 파일 처리 (서버 디스크로 복사)
    uploaded_files =
      consume_uploaded_entries(socket, :attachment, fn meta, entry ->
        # 파일을 저장할 실제 경로 생성 (예: priv/static/uploads 혹은 별도 스토리지)
        dest =
          Path.join([
            "priv",
            "static",
            "uploads",
            "#{entry.uuid}-#{entry.client_name}"
          ])

        # directory가 없으면 생성
        File.mkdir_p!(Path.dirname(dest))
        # 파일 복사
        File.cp!(meta.path, dest)

        # "/uploads/uuid-filename.jpg" 형태의 문자열을 반환
        url_path = static_path(socket, "/uploads/#{Path.basename(dest)}")

        # Attachment 스키마에 들어갈 맵 데이터 반환
        {:ok,
         %{
           "filename" => entry.client_name,
           "local_path" => url_path,
           "file_type" => entry.client_type,
           "byte_size" => entry.client_size
         }}
      end)

    # 2. comment_params에 attachments 리스트 병합
    # 키가 문자열("attachments")이어야 cast_assoc에서 인식됨
    params_with_files = Map.put(comment_params, "attachments", uploaded_files)

    # Comment Resource Type과 ID 전달 (Resource Type은 "Request"로 고정)
    # case Comments.create_comment("Request", request.id, current_user, params_with_files) do
    case Comments.create_comment(request, current_user, params_with_files) do
      {:ok, _comment} ->
        changeset = Comments.change_comment(%Comment{})
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # 첨부파일 업로드 취소 이벤트 처리
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_info({:comment_created, comment}, socket) do
    socket =
      socket
      |> stream_insert(:comments, comment)

    {:noreply, socket}
  end

  def handle_info({:request_updated, request}, socket) do
    {:noreply, assign(socket, :request, request)}
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
