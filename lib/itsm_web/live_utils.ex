defmodule ItsmWeb.LiveUtils do
  @moduledoc """
  ITSM 개발에 필요한 LiveView에서 사용할 Util메소드 정의 합니다.
  """
  require Logger
  alias Itsm.Accounts.User
  alias Phoenix.LiveView

  @doc """
  모든 에러 메세지를 통합적으로 처리하는 함수입니다. `reason`과 `scope`에 따라 적절한 사용자 친화적인 메시지를 반환합니다.
  또한, 알려지지 않은 에러 유형에 대해서는 로깅을 수행하여 디버깅에 도움을 줍니다.
  scope는 에러가 발생한 컨텍스트를 나타내며, 예를 들어 `:crew`는 크루 관련 에러임을 나타냅니다.
  reason은 에러의 유형을 나타내며, 예를 들어 `:not_leader`는 크루의 리더가 아닌 사용자가 리더 전용 작업을 시도했음을 나타냅니다.
  opt은 추가적인 정보를 제공하는데 사용될 수 있으며, 예를 들어 `:not_leader` 에러의 경우 어떤 메소드에서 발생했는지에 대한 정보를 담을 수 있습니다.
  """
  @spec translate_error(reason :: atom(), scope :: atom() | nil, opt :: any()) :: String.t()
  def translate_error(reason, scope \\ nil, opt \\ nil)

  def translate_error(:approval, _scope, _opt), do: gettext("Approval creation failed.")
  def translate_error(:attachment, _scope, _opt), do: gettext("Attachment upload failed.")
  def translate_error(:k_vms_required, _scope, _opt), do: gettext("minimum 1 VM must be inputed")

  def translate_error(:not_leader, :crew, opt) do
    case opt do
      "update_crew" -> gettext("Only the leader can edit this crew.")
      "delete_crew" -> gettext("Only the leader can delete this crew.")
      "siwtch_leader" -> gettext("You don't have permission to change the leader.")
    end
  end

  def translate_error(:not_in_crew, :crew, _opt),
    do: gettext("The selected user is not a member of this crew.")

  def translate_error(:unauthorized, :crew, _opt),
    do: gettext("You don't have permission to remove this member.")

  def translate_error(reason, scope, opt) do
    Logger.error("reason : #{reason}\nscope : #{scope}\nopt : #{opt}")
    gettext("An unknown error occurred.")
  end

  defp gettext(label), do: Gettext.gettext(ItsmWeb.Gettext, label)

  def fetch_safe(data, field, default \\ "") when is_atom(field) do
    if data, do: Map.get(data, field, default), else: default
  end

  def allow_uploads(%Phoenix.LiveView.Socket{} = socket, upload_key \\ :attachment) do
    LiveView.allow_upload(socket, upload_key,
      accept: ~w(.png .jpg .jpeg .bmp .gif),
      max_entries: 4,
      max_file_size: 1 * 1024 * 1024
    )
  end

  def build_attachment_consumer(%Phoenix.LiveView.Socket{} = socket, upload_key \\ :attachment) do
    fn -> consume_attachments(socket, upload_key) end
  end

  defp consume_attachments(%Phoenix.LiveView.Socket{} = socket, upload_key) do
    dest_dir = Application.get_env(:itsm, :upload_path) || "C:\\uploads"
    File.mkdir_p!(dest_dir)

    LiveView.consume_uploaded_entries(socket, upload_key, fn %{path: tmp_path}, entry ->
      extension = Path.extname(entry.client_name)
      final_file_name = "#{entry.uuid}#{extension}"
      dest_path = Path.join(dest_dir, final_file_name)
      File.cp!(tmp_path, dest_path)

      {:ok,
       %{
         "filename" => entry.client_name,
         "local_path" => dest_path,
         "file_type" => entry.client_type,
         "byte_size" => entry.client_size
       }}
    end)
  end

  def titleize(term) do
    term
    |> to_string()
    |> String.split(~r/[-_ ]/)
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def find_label(options, target) do
    Enum.find_value(options, "알 수 없음", fn {label, value} ->
      if value == target, do: label
    end)
  end

  @doc """
  PubSub을 통해 수신된 표준 이벤트를 처리하고 LiveView 상태를 업데이트합니다.

  이 함수는 다음과 같은 작업을 순차적으로 수행합니다:
  1. 이벤트 이름(`event`, :update_common_code)에서 앞에 있는 액션 타입(예: create, update, delete)을 추출합니다.
  2. 사용자에게 알림 메시지(Flash)를 표시합니다.
  3. 현재 LiveView의 `live_action` 상태에 따라 스트림 삭제, 데이터 재할당 또는 페이지 이동을 수행합니다.
  4. 편집 중인 리소스와 충돌이 발생할 경우(`:edit` 모드), 해당 FormComponent에 `send_update`를 보냅니다.

  이 함수는 공통적인 UI 로직(알림, 상태 변경, 충돌 감지)을 처리하며, `socket`을 반환하므로
  추가적인 상태 업데이트(예: 스트림 추가)가 필요한 경우 파이프라인으로 연결하여 사용할 수 있습니다.

  ## 매개변수
  - `socket`: 현재 LiveView의 socket.
  - `action_user`: 이벤트를 발생시킨 사용자의 정보 (`display_name` 필드 필요).
  - `event`: 발생한 이벤트 (예: `:project_updated`, `:user_deleted`).
  - `item`: 이벤트 대상이 되는 리소스 데이터 (Struct 또는 Map).
  - `opts`: 처리를 위한 옵션들.

  ## 옵션 (opts)
  - `:resource_name` - 메시지에 표시될 리소스의 이름 (예: gettext("Common Code"), "사용자").
  - `:context_key` - 리소스가 socket.assigns에 저장된 키 (예: `:common_code`). `:show` 액션에서 데이터 업데이트 시 사용됩니다.
  - `:stream_name` - `:index` 액션에서 `:delete` 이벤트 발생 시 스트림에서 제거할 이름.
  - `:flash_message` - 기본 메시지 대신 표시할 커스텀 메시지.
  - `:push_patch` - 액션 처리 후 이동할 경로 (`push_patch`), 있을 경우에만 이동.
  - `:push_navigate` - 액션 처리 후 이동할 경로 (`push_navigate`), 있을 경우에만 이동.
  - `:form_module` - 충돌 발생 시 업데이트를 보낼 컴포넌트 모듈 (기본값 `...FormComponent`).
  """
  @spec handle_standard_pubsub(
          socket :: Phoenix.LiveView.Socket.t(),
          action_user :: %{display_name: String.t()},
          event :: atom(),
          item :: map() | struct(),
          opts :: keyword()
        ) :: Phoenix.LiveView.Socket.t()
  def handle_standard_pubsub(socket, action_user, event, item, opts) do
    [action_type | _] = event |> Atom.to_string() |> String.split("_")

    action_user =
      if is_nil(action_user), do: %User{display_name: "anonymous_guest"}, else: action_user

    socket
    |> put_flash_by_event(action_user, action_type, opts)
    |> apply_action_type(action_type, item, opts)
    |> send_update_by_conflict(action_user, event, item, opts)
  end

  defp put_flash_by_event(socket, action_user, action_type, opts) do
    message =
      opts[:flash_message] || build_message(action_user, action_type, opts[:resource_name])

    Phoenix.LiveView.put_flash(socket, :info, message)
  end

  defp apply_action_type(%{assigns: %{live_action: :index}} = socket, "delete", item, opts),
    do: maybe_stream_delete(socket, opts[:stream_name], item)

  defp apply_action_type(%{assigns: %{live_action: :show}} = socket, "update", item, opts),
    do: maybe_assign_resource(socket, opts[:context_key], item)

  defp apply_action_type(%{assigns: %{live_action: :edit}} = socket, _event, _item, _opts),
    do: socket

  defp apply_action_type(%{assigns: %{live_action: :new}} = socket, _event, _item, _opts),
    do: socket

  defp apply_action_type(socket, _action_type, _item, opts) do
    cond do
      path = opts[:push_patch] -> Phoenix.LiveView.push_patch(socket, path)
      path = opts[:push_navigate] -> Phoenix.LiveView.push_navigate(socket, path)
      true -> socket
    end
  end

  defp send_update_by_conflict(socket, action_user, event, item, opts) do
    resource = socket.assigns[opts[:context_key]]
    current_id = if resource, do: to_string(resource.id), else: nil

    if current_id == to_string(item.id) and socket.assigns.live_action == :edit do
      form_module = get_form_module(socket, opts)
      Phoenix.LiveView.send_update(form_module, id: item.id, conflict: {event, action_user})
    end

    socket
  end

  defp build_message(action_user, "create", name),
    do: "#{action_user.display_name} #{gettext("Created")} #{name}"

  defp build_message(action_user, "update", name),
    do: "#{action_user.display_name} #{gettext("Updated")} #{name}"

  defp build_message(action_user, "delete", name),
    do: "#{action_user.display_name} #{gettext("Deleted")} #{name}"

  defp build_message(action_user, _, name),
    do: "#{action_user.display_name} #{gettext("Processed")} #{name}"

  defp get_form_module(socket, opts) do
    case opts[:form_module] do
      nil ->
        socket.view
        |> Module.split()
        |> List.replace_at(-1, "FormComponent")
        |> Module.concat()

      module ->
        module
    end
  end

  defp maybe_stream_delete(socket, name, item)
       when is_atom(name) and not is_nil(name) do
    Phoenix.LiveView.stream_delete(socket, name, item)
  end

  defp maybe_stream_delete(socket, _, _), do: socket

  defp maybe_assign_resource(socket, context_key, item) do
    current_resource = socket.assigns[context_key]

    if current_resource && to_string(current_resource.id) == to_string(item.id) do
      Phoenix.Component.assign(socket, context_key, item)
    else
      socket
    end
  end

  def live_select_params(attrs, fields, :single) when is_list(fields) do
    Enum.reduce(fields, attrs, fn field, acc ->
      process_empty_selection(acc, field, nil)
    end)
  end

  def live_select_params(attrs, fields, :tags) when is_list(fields) do
    Enum.reduce(fields, attrs, fn field, acc ->
      process_empty_selection(acc, field, [])
    end)
  end

  defp process_empty_selection(acc, field, default_value) do
    empty_key = "#{field}_empty_selection"

    case {Map.has_key?(acc, field), Map.has_key?(acc, empty_key)} do
      {false, true} -> Map.put(acc, field, default_value)
      _ -> acc
    end
  end
end
