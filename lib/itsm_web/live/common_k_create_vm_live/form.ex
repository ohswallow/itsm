defmodule ItsmWeb.CommonKCreateVmLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Service
  alias Itsm.Categories
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Crews
  alias ItsmWeb.LiveUtils
  alias Itsm.CommonCodes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> LiveUtils.allow_uploads()
     |> assign(:conflict, false)
     |> assign(:form, to_form(Requests.change_request(%Request{})))
     |> assign_new_options()}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Requests, id)
      Itsm.Utils.subscribes(Requests)
    end

    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
      options: Crews.search_live_select_crews(text, user)
    )

    {:noreply, socket}
  end

  def handle_event("save", %{"request" => params}, socket) do
    params = LiveUtils.live_select_params(params, ["referenced_crews"], :tags)
    save_request(socket, socket.assigns.live_action, params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:crew_options, fn -> Accounts.crew_ids_names(socket.assigns.current_user) end)
    |> assign_new(:env_options, fn -> CommonCodes.get_select_options("운영_구분") end)
    |> assign_new(:group_code_options, fn -> CommonCodes.get_select_options("운영체제") end)
    |> assign_new(:location_options, fn -> CommonCodes.get_select_options("장소") end)
    |> assign_new(:os_version_options, fn ->
      %{
        "리눅스" => CommonCodes.get_select_options("리눅스"),
        "윈도우" => CommonCodes.get_select_options("윈도우")
      }
    end)
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
    referenced_crews_options = Crews.list_live_select_crews(request)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_options, referenced_crews_options)
    |> assign(:form, to_form(Requests.change_request(request)))
  end

  defp apply_action(socket, :copy, %{"id" => id}) do
    request = Requests.get_request!(id)

    referenced_crews_options = Crews.list_live_select_crews(request)

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:referenced_crews_options, referenced_crews_options)
    |> assign(:form, to_form(Requests.change_request(request)))
  end

  defp save_request(socket, :edit, params) do
    %{current_user: user, request: request} = socket.assigns

    case Requests.update_request(user, request, params) do
      {:ok, updated_request} ->
        # reference 동기화 (기존 삭제 → 새로 생성)
        Crews.sync_crew_references("Request", updated_request.id, params["referenced_crews"])

        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, params) do
    %{current_user: user, category: category} = socket.assigns

    crews = Crews.get_crews(params["referenced_crews"])

    case Service.create_request(
           user,
           category,
           crews,
           fn -> LiveUtils.consume_attachments(socket) end,
           params
         ) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request.id}")}

      {:error, :request, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, step, _changeset, _so_far_changeset} ->
        changeset =
          socket.assigns.form.source
          |> Map.update!(:errors, &Enum.reject(&1, fn {k, _} -> k == :base end))
          |> Ecto.Changeset.add_error(:base, LiveUtils.translate_step_error(step))
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}
    end
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [context_key: :request]
    {:noreply, socket |> check_conflict(action_user, event, item, opts)}
  end

  defp check_conflict(socket, action_user, event, item, opts) do
    resource = socket.assigns[opts[:context_key]]
    current_id = if resource, do: to_string(resource.id), else: nil

    if current_id == to_string(item.id) and socket.assigns.live_action == :edit do
      msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

      socket
      |> assign(:conflict, true)
      |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 #{msg}했습니다.")
    else
      socket
    end
  end
end
