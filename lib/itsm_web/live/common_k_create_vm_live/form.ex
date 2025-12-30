defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Service.Request
  alias Itsm.Team
  alias Itsm.Accounts.User
  alias ItsmWeb.LiveUtils

  def mount(params, _session, socket) do
    crew_options = Accounts.crew_ids_names(socket.assigns.current_user)

    {:ok,
     socket
     |> allow_upload(:image,
       accept: ~w(.png .jpg),
       max_entries: 1,
       max_file_size: 2 * 1024 * 1024
     )
     |> assign(:assignee, %User{})
     |> assign(:crew_options, crew_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, %{"id" => category_id}) do
    category = Service.get_category!(String.to_integer(category_id))

    socket
    |> assign(:page_title, "New Request")
    |> assign(:category, category)
    |> assign(:request, %Request{})
    |> assign(:referenced_crews_id, [])
    |> assign(:form, to_form(Service.change_request(%Request{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    request = Service.get_request!(id)

    # 기존 referenced crews 로드
    referenced_crews_id =
      Team.list_reference(:service_request, id)
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

  def handle_params(_params, uri, socket) do
    IO.inspect(URI.parse(uri), label: "HANDLE_PARAMS URI")

    socket =
      socket
      |> assign(:show_user_modal, false)
      |> assign(:show_crew_modal, false)
      |> assign(:current_path, URI.parse(uri).path)

    {:noreply, socket}
  end

  def handle_info({ItsmWeb.SearchUserDialog, :user_selected, assignee}, socket) do
    params = LiveUtils.change_assignee_name(socket, assignee)
    changeset = Service.change_request(socket.assigns.request, params)

    socket =
      socket
      |> assign(:assignee, assignee)
      |> assign(:form, to_form(changeset, action: :validate))
      |> assign(:show_user_modal, false)

    {:noreply, socket}
  end

  def handle_info({ItsmWeb.SearchCrewsDialog, :crews_selected, crews_id}, socket) do
    socket =
      socket
      |> assign(:referenced_crews_id, crews_id)
      |> assign(:show_crew_modal, false)

    {:noreply, socket}
  end

  def handle_event("validate", %{"request" => request_params}, socket) do
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
    save_request(socket, socket.assigns.live_action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    %{current_user: user, request: request} = socket.assigns

    case Service.update_request(user, request, request_params) do
      {:ok, _request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_navigate(to: ~p"/requests")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    %{current_user: user, category: category, assignee: assignee} = socket.assigns

    case Service.create_full_request(user, category, assignee, request_params) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request.id}")}

      {:error, :request, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, :approval, _changeset, _so_far_changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "An error occurred while creating approval}")
         |> push_navigate(to: ~p"/requests")}
    end
  end

  defp save_request(socket, :copy, request_params) do
    case Service.create_request(socket.assigns.current_user, request_params) do
      {:ok, _request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request copied successfully")
         |> push_navigate(to: ~p"/requests")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
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
