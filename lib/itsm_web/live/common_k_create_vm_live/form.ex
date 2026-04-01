defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Categories
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Team
  alias Itsm.Crews
  alias ItsmWeb.LiveUtils

  def mount(params, _session, socket) do
    crew_options = Accounts.crew_ids_names(socket.assigns.current_user)

    {:ok,
     socket
     |> LiveUtils.allow_uploads()
     |> assign(:crew_options, crew_options)
     |> assign(:conflict, false)
     |> assign_new_options()
     |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(%{"id" => id}, uri, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Request, id)
      Itsm.Utils.subscribes(Request)
    end

    {:noreply, assign(socket, :current_path, URI.parse(uri).path)}
  end

  # ✅ 파일 업로드 취소 이벤트 (HTML의 phx-click="cancel" 처리)
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

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    %{current_user: user} = socket.assigns

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: Crews.live_select_by_name_user_name(text, user)
    )

    {:noreply, socket}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.live_action, request_params)
  end

  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:env_options, fn -> Itsm.CommonCodes.get_select_options("운영_구분") end)
    |> assign_new(:group_code_options, fn -> Itsm.CommonCodes.get_select_options("운영체제") end)
    |> assign_new(:os_version_options, fn ->
      %{
        "리눅스" => Itsm.CommonCodes.get_select_options("리눅스"),
        "윈도우" => Itsm.CommonCodes.get_select_options("윈도우")
      }
    end)
    |> assign_new(:location_options, fn -> Itsm.CommonCodes.get_select_options("장소") end)
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

  defp save_request(socket, :edit, request_params) do
    %{current_user: user, request: request} = socket.assigns

    crews_id = Map.get(request_params, "referenced_crews", [])

    case Requests.update_request(user, request, request_params) do
      {:ok, updated_request} ->
        Team.sync_references("Request", updated_request.id, crews_id)

        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    %{current_user: user, category: category} = socket.assigns

    # LiveSelect tags 값 추출
    crews_id = Map.get(request_params, "referenced_crews", [])

    case Service.create_request(
           user,
           category,
           fn -> LiveUtils.consume_attachments(socket) end,
           request_params
         ) do
      {:ok, request} ->
        # reference 생성
        Team.sync_references("Request", request.id, crews_id)

        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request.id}")}

      {:error, :request, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, step, _changeset, _so_far_changeset} ->
        changeset =
          socket.assigns.form.source
          |> Ecto.Changeset.add_error(:base, LiveUtils.translate_step_error(step))
          |> Map.put(:action, :insert)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}
    end
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"

  defp handle_pubsub(user, event, item, socket) do
    opts = [context_key: :request]
    IO.inspect(label: "test1")
    {:noreply, socket |> check_conflict(user, event, item, opts)}
  end

  defp check_conflict(socket, user, event, item, opts) do
    resource = socket.assigns[opts[:context_key]]
    current_id = if resource, do: to_string(resource.id), else: nil

    if current_id == to_string(item.id) and socket.assigns.live_action == :edit do
      msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

      socket
      |> assign(:conflict, true)
      |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")
    else
      socket
    end
  end
end
