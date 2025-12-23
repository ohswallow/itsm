defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Service.Request
  alias Itsm.Team
  alias Itsm.Approvals

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

  defp apply_action(socket, :new, %{"id" => category_id}) do
    category_id = String.to_integer(category_id)
    category = Service.get_category!(category_id)

    request = %Request{
      category_id: category.id,
      assignee_crew_id: category.assignee_crew_id
    }

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, [])
    |> assign(:form, to_form(Service.change_request(request)))
  end

  @impl true
  def handle_params(_params, uri, socket) do
    socket =
      socket
      |> assign(:show_user_modal, false)
      |> assign(:show_crew_modal, false)
      |> assign(:current_path, URI.parse(uri).path)

    {:noreply, socket}
  end

  @impl true
  def handle_info({ItsmWeb.SearchUserDialog, :user_selected, user}, socket) do
    changeset = Approvals.change_view_approval(socket.assigns.form.source, user)

    socket =
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:show_user_modal, false)

    {:noreply, socket}
  end

  def handle_info({ItsmWeb.SearchCrewsDialog, :crews_selected, crews_id}, socket) do
    # 여기서 crews_id를 어디에 저장할지 결정
    # 일단 나중에 따로 Reference 생성하거나, form param에 담을 수 있음
    socket =
      socket
      |> assign(:referenced_crews_id, crews_id)
      |> assign(:show_crew_modal, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    IO.inspect(request_params, label: "Request Params")

    changeset = Service.change_request(socket.assigns.request, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("open_user_modal", _, socket) do
    {:noreply, assign(socket, :show_user_modal, true)}
  end

  def handle_event("open_crew_modal", _, socket) do
    {:noreply, assign(socket, :show_crew_modal, true)}
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
end
