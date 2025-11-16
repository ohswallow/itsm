defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Service
  alias Itsm.Service.Request
  alias Itsm.Team

  on_mount {ItsmWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(params, _session, socket) do
    crews = Team.list_my_crews(socket.assigns.current_user)
    crew_options = Enum.map(crews, &{&1.name, &1.id})

    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.png .jpg),
       max_entries: 1,
       max_file_size: 2 * 1024 * 1024
     )
     |> assign(:my_crews, crew_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    request = Service.get_request!(id)

    # 기존 referenced crews 로드
    referenced_crews_id =
      Team.list_reference("Request", id)
      |> Enum.map(& &1.crew_id)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, referenced_crews_id)
    |> assign(:form, to_form(Service.change_request(request)))
  end

  defp apply_action(socket, :copy, %{"id" => id}) do
    request = Service.get_request!(id)

    # copy할 때도 기존 crews 로드
    referenced_crews_id =
      Team.list_reference("Request", id)
      |> Enum.map(& &1.crew_id)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, referenced_crews_id)
    |> assign(:form, to_form(Service.change_request(request)))
  end

  # defp apply_action(socket, :new, params) do
  defp apply_action(socket, :new, %{"category_id" => category_id}) do
    category_id = String.to_integer(category_id)
    category = Service.get_category!(category_id)

    request = %Request{
      category_id: category.id,
      assignee_crew_id: category.assignee_crew_id
    }

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    # 이 줄 추가!
    |> assign(:referenced_crews_id, [])
    |> assign(:form, to_form(Service.change_request(request)))
  end

  # 이 clause 추가 - modal 닫고 돌아올 때
  defp apply_action(socket, :new, _params) do
    socket
  end

  @impl true
  def handle_params(params, _url, socket) do
    IO.inspect(params, label: "HANDLE_PARAMS Params")

    # show? = params["modal"] == "search_user"
    # {:noreply, assign(socket, :show_user_modal, show?)}
    show_user_modal? = params["modal"] == "search_user"
    show_crew_modal? = params["modal"] == "search_crews"

    {:noreply,
     socket
     |> assign(:show_user_modal, show_user_modal?)
     |> assign(:show_crew_modal, show_crew_modal?)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>{@page_title}</.header>

    <.form for={@form} id="request-form" phx-change="validate" phx-submit="save">
      <%!-- <input type="hidden" name="request[category_id]" value={@request.category_id} /> --%>
      <input type="hidden" name={@form[:category_id].name} value={@request.category_id} />
      <%!-- <input type="hidden" name="request[assignee_crew_id]" value={@request.assignee_crew_id} /> --%>
      <input type="hidden" name={@form[:assignee_crew_id].name} value={@request.assignee_crew_id} />
      <%!-- <input type="hidden" name="request[requestor_id]" value={@current_user.id} /> --%>
      <input type="hidden" name={@form[:requestor_id].name} value={@current_user.id} />
      <%!-- <input type="hidden" name="request[requestor_name]" value={@current_user.display_name} /> --%>
      <input type="hidden" name={@form[:requestor_name].name} value={@current_user.display_name} />
      <.input
        field={@form[:requestor_crew_id]}
        type="select"
        label="My Crew"
        prompt="Choose a crew"
        options={@my_crews}
        required
      /> <.input field={@form[:title]} type="text" label="Title" phx-debounce />
      <.input
        field={@form[:description]}
        type="textarea"
        label="Description"
        phx-hook="MaintainHeight"
      />
      <.input
        field={@form[:env]}
        type="select"
        label="Environment"
        prompt="Choose an environment"
        options={[운영: :prod, 스테이징: :stg, 개발: :dev, DR: :dr]}
      /> <.input field={@form[:due_date]} type="datetime-local" label="Due Date" />
      <div class="mb-6">
        <h2 class="text-lg font-semibold text-zinc-700">VM 생성 요청</h2>
        
        <button
          class="mt-4 text-zinc-700"
          name="request[common_k_create_vms_sort][]"
          phx-click={JS.dispatch("change")}
          type="button"
          value="new"
        >
          <.icon name="hero-plus-circle" class="h-5 w-5 relative top-[-1px]" /> add more
        </button>
        <div id="request-inputs" class="p-4 space-y-6">
          <.inputs_for :let={common_k_create_vm_f} field={@form[:common_k_create_vms]}>
            <%!-- <div class="flex items-center mt-4 mb-2 space-x-2">
              <.icon name="hero-bars-3" class="cursor-pointer relative w-5 h-5 mr-2 -top-1" /> --%>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                type="hidden"
                name="request[common_k_create_vms_sort][]"
                value={common_k_create_vm_f.index}
              />
              <.input
                field={common_k_create_vm_f[:hostname]}
                label="호스트명"
                type="text"
                phx-debounce
              />
              <.input
                field={common_k_create_vm_f[:description]}
                label="서버 설명"
                type="text"
                phx-debounce
              />
              <.input
                field={common_k_create_vm_f[:os_image]}
                label="OS 종류"
                type="select"
                prompt="Choose a value"
                options={Ecto.Enum.values(Itsm.Service.CommonKCreateVm, :os_image)}
              />
              <.input
                field={common_k_create_vm_f[:os_version]}
                type="select"
                label="OS 버전"
                prompt="Choose a value"
                options={os_version_options_for(common_k_create_vm_f)}
              />
              <.input
                field={common_k_create_vm_f[:cpu_memory]}
                label="CPU/메모리"
                type="text"
                phx-debounce
              />
            </div>
            
            <button
              type="button"
              name="request[common_k_create_vms_drop][]"
              value={common_k_create_vm_f.index}
              phx-click={JS.dispatch("change")}
              class="relative -top-1"
            >
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </.inputs_for>
        </div>
         <input type="hidden" name="request[common_k_create_vms_drop][]" />
      </div>
       <%!-- 승인자 섹션 --%>
      <.input
        field={@form[:assignee_name]}
        type="text"
        label="승인자"
        readonly
        placeholder="이곳을 클릭하세요"
        phx-click={JS.patch(modal_path(@live_action, @request, "search_user"))}
      /> <input type="hidden" name={@form[:assignee_id].name} value={@form[:assignee_id].value} />
      <%= for {msg, _} <- @form[:assignee_id].errors do %>
        <p class="text-red-500 text-sm">{msg}</p>
      <% end %>
       <%!-- 참조 Crew 섹션 --%>
      <%!-- <.input
        type="text"
        label="참조 Crew"
        readonly
        value={
          Enum.map(@referenced_crews_id, fn crew_id -> Team.get_crew!(crew_id).name end)
          |> Enum.join(", ")
        }
        placeholder="선택된 crew가 없습니다"
        phx-click={JS.patch(modal_path(@live_action, @request, "search_crews"))}
      /> --%>
      <div class="mb-6">
        <label class="block text-sm font-semibold text-zinc-700 mb-2">참조 Crew</label>
        <input
          type="text"
          readonly
          value={
            Enum.map(@referenced_crews_id, fn crew_id -> Team.get_crew!(crew_id).name end)
            |> Enum.join(", ")
          }
          placeholder="선택된 crew가 없습니다"
          phx-click={JS.patch(modal_path(@live_action, @request, "search_crews"))}
          class="w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100 cursor-pointer"
        />
      </div>
      
      <div class="flex">
        <.button phx-disable-with="Saving...">Save Recipe</.button>
        <.loading_spinner class="hidden phx-submit-loading:inline-block ml-4 mb-5" />
      </div>
      
      <.error :if={@form.source.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
    </.form>

    <.modal
      :if={@show_user_modal}
      id="user-search"
      on_cancel={JS.patch(base_path(@live_action, @request))}
      show
    >
      <.live_component module={ItsmWeb.SearchUserDialog} id="search-user" parent_pid={self()} />
    </.modal>

    <.modal
      :if={@show_crew_modal}
      id="crews-search"
      on_cancel={JS.patch(base_path(@live_action, @request))}
      show
    >
      <.live_component
        module={ItsmWeb.Components.SearchCrewsDialog}
        id="search-crews"
        parent_pid={self()}
      />
    </.modal>

    <.back navigate={~p"/categories"}>Back</.back>
    """
  end

  @impl true
  def handle_info({:user_selected, user_id, user_name, user_number}, socket) do
    IO.inspect({user_id, user_name, user_number}, label: "User selected")

    # 현재 form의 params 가져오기
    current_params = socket.assigns.form.params

    # 승인자 정보를 params에 추가
    updated_params =
      current_params
      # |> Map.put("assignee_id", user_number)
      |> Map.put("assignee_id", user_id)
      |> Map.put("assignee_name", user_name)

    IO.inspect(updated_params, label: "Updated params")

    # params와 함께 changeset 생성
    changeset = Service.change_request(socket.assigns.request, updated_params)

    IO.inspect(changeset, label: "Changeset")

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:show_user_modal, false)}
  end

  def handle_info({:crews_selected, crews_id}, socket) do
    IO.inspect(crews_id, label: "Crews selected")

    # 여기서 crews_id를 어디에 저장할지 결정
    # 일단 나중에 따로 Reference 생성하거나, form param에 담을 수 있음

    {:noreply,
     socket
     |> assign(:referenced_crews_id, crews_id)
     |> assign(:show_crew_modal, false)}
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    IO.inspect(request_params, label: "Request Params")

    changeset = Service.change_request(socket.assigns.request, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    # category_id가 비어있으면 socket.assigns.request에서 가져옴
    request_params =
      if request_params["category_id"] in [nil, ""] do
        Map.put(request_params, "category_id", socket.assigns.request.category_id)
      else
        request_params
      end

    # status가 비어있으면 :check로 설정
    request_params =
      if request_params["status"] in [nil, ""] do
        Map.put(request_params, "status", :check)
      else
        request_params
      end

    case save_request(socket, socket.assigns.live_action, request_params) do
      {:ok, _request} ->
        flash_msg =
          case socket.assigns.live_action do
            :new -> "Request created successfully"
            :edit -> "Request updated successfully"
            :copy -> "Request created successfully"
          end

        {:noreply,
         socket
         |> put_flash(:info, flash_msg)
         |> push_navigate(to: ~p"/requests")}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset.errors, label: "Changeset Errors")
        # {:noreply, assign(socket, form: to_form(changeset))}
        {:noreply, assign(socket, form: to_form(changeset, action: :insert))}
    end
  end

  defp save_request(socket, :edit, request_params) do
    Service.update_request(socket.assigns.current_user, socket.assigns.request, request_params)
  end

  defp save_request(socket, :new, request_params) do
    with {:ok, request} <- Service.create_request(socket.assigns.current_user, request_params),
         {:ok, _approval} <-
           Service.create_approval(%{
             # 여기가 핵심!
             "status" => "request",
             "approver_id" => socket.assigns.current_user.id,
             "approver_name" => socket.assigns.current_user.display_name,
             "request_id" => request.id
           }) do
      {:ok, request}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp save_request(socket, :copy, request_params) do
    Service.create_request(socket.assigns.current_user, request_params)
  end

  # os_image에 따라 os_version 옵션 동적 변경
  defp os_version_options_for(common_k_create_vm_f) do
    common_k_create_vm_f.source
    |> Ecto.Changeset.get_field(:os_image)
    |> get_os_version_options()
  end

  # 템플릿에서 사용할 수 있도록 private가 아닌 함수로
  defp get_os_version_options(:Linux),
    do: [{"RHEL 9.6 (보안)", "sec_rhel9_6"}, {"RHEL 9.6 (일반)", "nosec_rhel9_6"}]

  defp get_os_version_options(:Windows),
    do: [{"Windows Server 2022", "win22"}, {"Windows Server 2025", "win25"}]

  defp get_os_version_options(_), do: []

  # defp modal_path(:new, _request) do
  #   ~p"/common_k_create_vm/new?modal=search_user"
  # end

  # defp modal_path(:edit, request) do
  #   ~p"/common_k_create_vm/#{request.id}/edit?modal=search_user"
  # end

  # defp modal_path(:copy, request) do
  #   ~p"/common_k_create_vm/#{request.id}/copy?modal=search_user"
  # end

  defp modal_path(:new, _request, modal_type) do
    ~p"/common_k_create_vm/new?modal=#{modal_type}"
  end

  defp modal_path(:edit, request, modal_type) do
    ~p"/common_k_create_vm/#{request.id}/edit?modal=#{modal_type}"
  end

  defp modal_path(:copy, request, modal_type) do
    ~p"/common_k_create_vm/#{request.id}/copy?modal=#{modal_type}"
  end

  defp base_path(:new, _request) do
    ~p"/common_k_create_vm/new"
  end

  defp base_path(:edit, request) do
    ~p"/common_k_create_vm/#{request.id}/edit"
  end

  defp base_path(:copy, request) do
    ~p"/common_k_create_vm/#{request.id}/copy"
  end
end
