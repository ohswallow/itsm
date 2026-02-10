defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Categories
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Team
  alias Itsm.Crews
  alias Itsm.Members
  alias ItsmWeb.LiveUtil

  def mount(params, _session, socket) do
    crew_options = Accounts.crew_ids_names(socket.assigns.current_user)

    {:ok,
     socket
     |> LiveUtil.allow_uploads()
     |> assign(:crew_options, crew_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, %{"id" => category_id}) do
    category = Categories.get_category!(String.to_integer(category_id))

    socket
    |> assign(:page_title, "New Request")
    |> assign(:category, category)
    |> assign(:request, %Request{})
    |> assign(:referenced_crews_options, [])
    |> assign(:form, to_form(Requests.change_request(%Request{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    request = Requests.get_request!(id)

    # 기존 referenced crews를 옵션 맵으로 로드 (label 유지를 위해)
    referenced_crews_options =
      Team.list_reference("Request", id)
      |> Enum.map(fn ref ->
        crew = Crews.get_crew!(ref.crew_id)
        %{label: crew.name, tag_label: crew.name, value: crew.id}
      end)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_options, referenced_crews_options)
    |> assign(:form, to_form(Requests.change_request(request)))
  end

  defp apply_action(socket, :copy, %{"id" => id}) do
    request = Requests.get_request!(id)

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_options, [])
  end

  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, :current_path, URI.parse(uri).path)}
  end

  # ✅ 파일 업로드 취소
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("validate", %{"request" => request_params}, socket) do
    # LiveSelect tags 값을 옵션 맵으로 동기화 (label 유지를 위해)
    referenced_crews_options =
      cond do
        # 태그가 있으면 → 옵션 맵 동기화
        is_list(request_params["referenced_crews"]) ->
          crews_id = request_params["referenced_crews"]
          existing = socket.assigns.referenced_crews_options
          existing_map = Map.new(existing, fn opt -> {opt.value, opt} end)

          Enum.map(crews_id, fn id ->
            case Map.get(existing_map, id) do
              nil ->
                crew = Crews.get_crew!(id)
                %{label: crew.name, tag_label: crew.name, value: id}

              opt ->
                opt
            end
          end)

        # 모든 태그 삭제됨 → 빈 리스트
        Map.has_key?(request_params, "referenced_crews_empty_selection") ->
          []

        # 그 외 (다른 필드 변경) → 기존 유지
        true ->
          socket.assigns.referenced_crews_options
      end

    changeset = Requests.change_request(%Request{}, request_params)

    {:noreply,
     socket
     |> assign(:referenced_crews_options, referenced_crews_options)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  # ✅ LiveSelect 검색 - Crew 이름 + Member 이름으로 검색
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    # 1. Crew 이름으로 직접 검색
    crews_by_name = Crews.search_crews_by_name(text)

    # 2. Member 이름(user.display_name)으로 검색 → Crew 찾기
    users = Accounts.search_users(%{"q" => text})
    crews_by_member = Members.search_crews_by_member(users)

    # 3. 중복 제거
    crews =
      (crews_by_name ++ crews_by_member)
      |> Enum.uniq_by(& &1.id)

    options =
      Enum.map(crews, fn crew ->
        %{
          label: crew.name,
          tag_label: crew.name,
          value: crew.id,
          description: crew.description
        }
      end)

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: options
    )

    {:noreply, socket}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.live_action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    %{current_user: user, request: request} = socket.assigns

    # LiveSelect tags 값 추출 (없으면 빈 리스트)
    crews_id = Map.get(request_params, "referenced_crews", [])
    clean_params = Map.delete(request_params, "referenced_crews")
    # LiveSelect 관련 추가 키도 제거
    clean_params =
      Map.drop(clean_params, ["referenced_crews_text_input", "referenced_crews_empty_selection"])

    case Requests.update_request(user, request, clean_params) do
      {:ok, updated_request} ->
        # reference 동기화 (기존 삭제 → 새로 생성)
        Team.sync_references("Request", updated_request.id, crews_id)

        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    %{current_user: user, category: category} = socket.assigns

    # LiveSelect tags 값 추출
    crews_id = Map.get(request_params, "referenced_crews", [])
    clean_params = Map.delete(request_params, "referenced_crews")

    case Service.create_request(
           user,
           category,
           fn -> LiveUtil.consume_attachments(socket) end,
           clean_params
         ) do
      {:ok, request} ->
        # reference 생성
        Team.sync_references("Request", request.id, crews_id)

        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request.id}")}

      {:error, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, step, _changeset, _so_far_changeset} ->
        changeset =
          socket.assigns.form.source
          |> Ecto.Changeset.add_error(:base, LiveUtil.handle_multi_error(step))
          |> Map.put(:action, :insert)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}
    end
  end

  # os_image에 따라 os_version 옵션 동적 변경
  defp os_version_options_for(common_k_create_vm_f) do
    common_k_create_vm_f.source
    |> Ecto.Changeset.get_field(:os_image)
    |> get_os_version_options()
  end

  defp get_os_version_options(:Linux),
    do: [{"RHEL 9.6 (보안)", "sec_rhel9_6"}, {"RHEL 9.6 (일반)", "nosec_rhel9_6"}]

  defp get_os_version_options(:Windows),
    do: [{"Windows Server 2022", "win22"}, {"Windows Server 2025", "win25"}]

  defp get_os_version_options(_), do: []

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
