defmodule ItsmWeb.CommonKCreateVmLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Service
  alias Itsm.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Requests

  def mount(_params, _session, socket) do
    changeset = Comments.change_comment(%Comment{})
    socket = assign(socket, :form, to_form(changeset))
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      Requests.subscribe_request(id)
    end

    request = Requests.get_request!(id)
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
        <.comment :for={{dom_id, comment} <- @streams.comments} comment={comment} id={dom_id} />
      </div>
    </div>

    <div :if={@request.status != :closed}>
      <.form for={@form} id="comment-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:comment]} type="textarea" placeholder="Comment..." />
        <.button>Add Comment</.button>
      </.form>
    </div>

    <.back navigate={~p"/requests"}>Back</.back>
    """
  end

  attr :id, :string, required: true
  attr :comment, Comment, required: true

  def comment(assigns) do
    ~H"""
    <div class="space-y-4 mb-6" id={@id}>
      <div class="flex-1">
        <div class="flex items-center gap-2 mb-1">
          <span class="font-semibold text-slate-900">{@comment.user.display_name}</span>
          <span class="text-xs text-slate-500">{@comment.inserted_at}</span>
        </div>
        
        <p class="text-sm text-slate-700 bg-slate-50 rounded-lg p-3">{@comment.comment}</p>
      </div>
    </div>
    """
  end

  # 모달 열기/닫기 이벤트
  def handle_event("view_attachment", %{"id" => id}, socket) do
    attachment = Enum.find(socket.assigns.request.attachments, &(&1.id == id))
    {:noreply, assign(socket, :selected_attachment, attachment)}
  end

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
    %{request: request, current_user: user} = socket.assigns

    case Comments.create_comment(request, user, comment_params) do
      {:ok, _comment} ->
        changeset = Comments.change_comment(%Comment{})

        IO.inspect(socket.assigns.streams.comments, label: "Comments Stream Before Insert")

        socket = assign(socket, :form, to_form(changeset))

        IO.inspect(socket.assigns.streams.comments, label: "Comments Stream After Insert")
        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
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
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_file_size(bytes), do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"
end
