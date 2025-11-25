defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Service.Request
  alias Itsm.Team

  on_mount {ItsmWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(params, _session, socket) do
    crew_options = Accounts.crew_ids_names(socket.assigns.current_user)

    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.png .jpg),
       max_entries: 1,
       max_file_size: 2 * 1024 * 1024
     )
     |> assign(:crew_options, crew_options)
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

  #  modal 닫고 돌아올 때
  defp apply_action(socket, :new, _params) do
    # 기본 request 생성
    request = %Request{
      category_id: nil,
      assignee_crew_id: nil
    }

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, [])
    |> assign(:form, to_form(Service.change_request(request)))
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
