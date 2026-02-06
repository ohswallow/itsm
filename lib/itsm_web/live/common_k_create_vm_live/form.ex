defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Categories
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Team

  def mount(params, _session, socket) do
    crew_options = Accounts.crew_ids_names(socket.assigns.current_user)

    {:ok,
     socket
     |> allow_upload(:attachment,
       accept: ~w(.png .jpg .jpeg .bmp .gif),
       max_entries: 4,
       max_file_size: 1 * 1024 * 1024
     )
     |> assign(:crew_options, crew_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  # TODO: 요청에 대한 참조 Crew 기능 추가 필요함
  defp apply_action(socket, :new, %{"id" => category_id}) do
    category = Categories.get_category!(String.to_integer(category_id))

    socket
    |> assign(:page_title, "New Request")
    |> assign(:category, category)
    |> assign(:request, %Request{})
    |> assign(:referenced_crews_id, [])
    |> assign(:form, to_form(Requests.change_request(%Request{})))
  end

  # TODO: 요청에 대한 수정에 대한 결제자 변경 기능 및  참조할 Crew 변경 기능이 필요함
  defp apply_action(socket, :edit, %{"id" => id}) do
    request = Requests.get_request!(id)

    # 기존 referenced crews 로드
    referenced_crews_id =
      Team.list_reference(:service_request, id)
      |> Enum.map(& &1.crew_id)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, referenced_crews_id)
    |> assign(:form, to_form(Requests.change_request(request)))
  end

  # TODO: 요청을 복사하는 기능 구현 필요함
  defp apply_action(socket, :copy, %{"id" => id}) do
    request = Requests.get_request!(id)

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_id, [])
  end

  def handle_params(_params, uri, socket) do
    socket =
      socket
      |> assign(:show_crew_modal, false)
      |> assign(:current_path, URI.parse(uri).path)

    {:noreply, socket}
  end

  def handle_info({ItsmWeb.SearchCrewsDialog, :crews_selected, crews_id}, socket) do
    socket =
      socket
      |> assign(:referenced_crews_id, crews_id)
      |> assign(:show_crew_modal, false)

    {:noreply, socket}
  end

  # ✅ 파일 업로드 취소 이벤트 (HTML의 phx-click="cancel" 처리)
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = Requests.change_request(%Request{}, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("open_crew_modal", _, socket) do
    {:noreply, assign(socket, :show_crew_modal, true)}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.live_action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    %{current_user: user, request: request} = socket.assigns

    case Requests.update_request(user, request, request_params) do
      {:ok, _request} ->
        {
          :noreply,
          socket
          |> put_flash(:info, "Request updated successfully")
          #  |> push_navigate(to: ~p"/requests")
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # TODO: refrence_crews_id  구조체 처리
  defp save_request(socket, :new, request_params) do
    %{current_user: user, category: category} = socket.assigns
    # assignee = Accounts.get_user(assignee_id)

    case Service.create_request(
           user,
           category,
           request_params,
           consume_attachments(socket)
         ) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Request creation failed: #{inspect(reason)}")}
    end
  end

  # ✅ 파일을 디스크에 저장하고, DB용 맵 리스트를 반환하는 함수
  defp consume_attachments(socket) do
    consume_uploaded_entries(socket, :attachment, fn meta, entry ->
      # 저장 경로 (priv/static/uploads)
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

      # Attachment 스키마에 들어갈 Map 반환
      {:ok,
       %{
         "filename" => entry.client_name,
         "local_path" => url_path,
         "file_type" => entry.client_type,
         "byte_size" => entry.client_size
       }}
    end)
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

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
