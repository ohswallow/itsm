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
  alias Itsm.Attachments

  import ItsmWeb.CommonKCreateVmLive.Components

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> LiveUtils.allow_uploads()
     |> assign(:conflict, false)
     |> assign(:form, to_form(Requests.change_request(%Request{})))
     |> assign(:selected_attachment, nil)
     |> assign_new_options()}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> Itsm.PubSub.Helper.subscribe(Requests, id: id)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # ✅ 파일 업로드 취소 이벤트 (HTML의 phx-click="cancel" 처리)
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("validate", %{"request" => params}, socket) do
    changeset = Requests.change_request(%Request{}, params)

    {:noreply,
     socket
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

  def handle_event("delete_attachment", %{"id" => id}, socket) do
    %{current_user: action_user} = socket.assigns

    case Attachments.delete_attachment(action_user, id) do
      {:ok, attachment} ->
        {:noreply, stream_delete(socket, :attachments, attachment)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete attachment.")}
    end
  end

  def handle_event("view_attachment", %{"id" => id, "filename" => filename}, socket) do
    {:noreply, assign(socket, :selected_attachment, %{id: id, filename: filename})}
  end

  def handle_event("close_attachment", _, socket) do
    {:noreply, assign(socket, :selected_attachment, nil)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:crew_options, fn -> Accounts.crew_ids_names(socket.assigns[:current_user]) end)
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
    |> assign(:form, to_form(Requests.change_request(%Request{})))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    request =
      Requests.get_request!(id)
      |> Requests.with_assoc(crew_references: [crew: [:users]])
      |> Requests.assign_referenced_crews()

    attachments = Attachments.get_list_attachments(request)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign(:form, to_form(Requests.change_request(request)))
    |> assign(:attachments_count, length(attachments))
    |> stream(:attachments, attachments, reset: true)
  end

  defp apply_action(socket, :copy, %{"id" => id}) do
    request = Requests.get_request!(id)

    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, request)
    |> assign(:form, to_form(Requests.change_request(request)))
  end

  defp save_request(socket, :edit, params) do
    %{current_user: action_user, request: request} = socket.assigns

    case Service.update_request(
           action_user,
           request,
           LiveUtils.build_attachment_consumer(socket),
           params
         ) do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_navigate(to: ~p"/common_k_create_vm/#{request}")}

      {:error, :request, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, step, _changeset, _so_far_changeset} ->
        socket.assigns.form.source
        |> Map.update!(:errors, &Enum.reject(&1, fn {k, _} -> k == :base end))
        |> Ecto.Changeset.add_error(:base, LiveUtils.translate_error(step))
        |> Map.put(:action, :validate)
    end
  end

  defp save_request(socket, :new, params) do
    %{current_user: action_user, category: category} = socket.assigns

    crews = Crews.get_crews(params["referenced_crews"])

    case Service.create_request(
           action_user,
           category,
           crews,
           LiveUtils.build_attachment_consumer(socket),
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
          |> Ecto.Changeset.add_error(:base, LiveUtils.translate_error(step))
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}
    end
  end

  defp referenced_crews_value_mapper(value) do
    %{name: name} = Crews.get_crew!(value)
    %{label: name, value: value}
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [target_key: :request]
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
