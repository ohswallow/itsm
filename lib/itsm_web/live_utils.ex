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
    base_dir = Application.get_env(:itsm, :upload_path) || "C:/uploads"

    date_path = Calendar.strftime(Date.utc_today(), "%Y/%m/%d")
    dest_dir = Path.join(base_dir, date_path)
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

  @spec get_sub_field(atom() | binary(), Phoenix.HTML.FormField.t(), map(), binary()) ::
          Phoenix.HTML.FormField.t()
  def get_sub_field(key, form_field, params, default_value \\ "")

  def get_sub_field(key, %Phoenix.HTML.FormField{} = form_field, params, default_value)
      when is_atom(key) do
    param_value = params[key] || params[Atom.to_string(key)]

    form_value =
      if is_struct(form_field.value) do
        Map.get(form_field.value, key)
      else
        Map.get(form_field.value || %{}, key) ||
          Map.get(form_field.value || %{}, Atom.to_string(key))
      end

    current_value = param_value || form_value || default_value

    form_field
    |> to_sub_form(params)
    |> get_in([key])
    |> Map.put(:value, current_value)
  end

  def get_sub_field(key, %Phoenix.HTML.FormField{} = form_field, params, default_value)
      when is_binary(key) do
    param_value = params[key]

    form_value =
      if is_struct(form_field.value) do
        Map.get(form_field.value, key)
      else
        Map.get(form_field.value || %{}, key)
      end

    current_value = param_value || form_value || default_value

    form_field
    |> to_sub_form(params)
    |> get_in([String.to_atom(key)])
    |> Map.put(:value, current_value)
  end

  def to_sub_form(%Phoenix.HTML.FormField{} = form_field, params) do
    %Phoenix.HTML.Form{} = base_form = form_field.form

    %Phoenix.HTML.Form{
      base_form
      | id: form_field.id,
        name: form_field.name,
        errors: List.flatten(form_field.errors),
        params: params || %{}
    }
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

  @doc """
  다른 노드나 프로세스로부터 수신한 표준 PubSub 이벤트를 처리하여 LiveView 소켓의 상태를 동기화하고 유저 피드백을 처리합니다.

  이 함수는 이벤트명(예: `:update_post`, `:delete_post`)에서 액션 유형(`"update"`, `"delete"`)을 동적으로 추출하여 플래시 메시지를 띄우고, 현재 화면의 `live_action` 상태에 따라 스트림 삭제, 리소스 재할당, 혹은 페이지 리다이렉션을 수행합니다. 또한, 현재 사용자가 편집 중인 항목에 다른 유저의 변경이 감지되면 컴포넌트에 충돌(Conflict) 알림을 보냅니다.

  ## 옵션 (Options)
    * `:live_action` - 현재 화면의 라이브 액션 상태 (예: `:index`, `:show`, `:edit`, `:new`). 지정하지 않으면 `socket.assigns.live_action`을 기본값으로 사용합니다.
    * `:resource_name` - 플래시 메시지 생성 시 사용할 리소스의 한국어/영어 명칭 (예: `"게시글"`, `"Post"`).
    * `:flash_message` - 자동으로 생성되는 메시지 대신 명시적으로 보여줄 커스텀 알림 메시지.
    * `:target_key` - 목록 화면(`:index`)에서 `"delete"` 액션 발생 시, 프론트엔드에서 즉시 제거할 LiveView 스트림의 이름 (예: `:posts`). 또는 상세 화면 및 편집 충돌 감지 시, `socket.assigns`에서 현재 리소스를 조회할 키 (예: `:post`).
    * `:form_module` - 편집 충돌 발생 시 `send_update/2`를 전달받을 부모 혹은 자식 LiveComponent 모듈. 지정하지 않을 경우 현재 LiveView 파일명을 기반으로 `{현재뷰}FormComponent`를 자동 추론합니다.
    * `:push_patch` - 매칭되는 특정 액션 처리가 없을 때 이동할 `push_patch` 경로.
    * `:push_navigate` - 매칭되는 특정 액션 처리가 없을 때 이동할 `push_navigate` 경로.

  ## 주요 내부 메커니즘
  1. **이벤트 파싱:** 인자로 넘어온 `event` 아톰을 문자열로 바꾼 뒤 언더바(`_`) 기준으로 쪼개어 첫 번째 단어를 `action_type`으로 인식합니다 (예: `:create_user` ➡️ `"create"`).
  2. **상태 동기화 (`apply_action_type/5`):**
     * `:index` 화면에서 `"delete"` 발생 시 ➡️ 화면에서 스트림을 즉시 제거합니다 (`stream_delete`).
     * `:show` 화면에서 `"update"` 발생 시 ➡️ 보고 있던 리소스 ID와 일치하면 변경된 새 데이터로 덮어씁니다 (`assign`).
  3. **동시 수정 충돌 감지 (`send_update_by_conflict/5`):**
     * 사용자가 현재 특정 항목을 수정 중인 상태(`live_action == :edit`)에서, 다른 누군가가 동일한 항목을 수정하거나 삭제하여 이벤트를 발행했다면, 해당 폼 컴포넌트(`FormComponent`)로 `conflict: {event, action_user}` 메시지를 원격 주입(`send_update`)하여 화면에 경고를 띄우거나 방어 처리를 유도합니다.
  """
  @spec handle_standard_pubsub(
          socket :: Phoenix.LiveView.Socket.t(),
          action_user :: %{display_name: String.t()},
          event :: atom(),
          item :: map() | struct(),
          opts :: [
            {:resource_name, String.t()}
            | {:target_key, atom()}
            | {:flash_message, String.t()}
            | {:push_patch, [{:to, String.t()} | {:replace, boolean()}]}
            | {:push_navigate, [{:to, String.t()} | {:replace, boolean()}]}
            | {:form_module, module()}
            | {:live_action, atom()}
          ]
        ) :: Phoenix.LiveView.Socket.t()
  def handle_standard_pubsub(socket, action_user, event, item, opts) do
    live_action = Keyword.get(opts, :live_action, socket.assigns.live_action)
    opts = Keyword.put(opts, :live_action, live_action)

    [action_type | _] = event |> Atom.to_string() |> String.split("_")

    action_user =
      if is_nil(action_user), do: %User{display_name: "anonymous_guest"}, else: action_user

    socket
    |> put_flash_by_event(action_user, action_type, opts)
    |> apply_action_type(action_type, item, live_action, opts)
    |> send_update_by_conflict(action_user, event, item, live_action, opts)
  end

  defp put_flash_by_event(socket, action_user, action_type, opts) do
    message =
      opts[:flash_message] || build_message(action_user, action_type, opts[:resource_name])

    Phoenix.LiveView.put_flash(socket, :info, message)
  end

  defp apply_action_type(socket, "delete", item, :index, opts),
    do: maybe_stream_delete(socket, opts[:target_key], item)

  defp apply_action_type(socket, "update", item, :show, opts),
    do: maybe_assign_resource(socket, opts[:target_key], item)

  defp apply_action_type(socket, _event, _item, :edit, _opts),
    do: socket

  defp apply_action_type(socket, _event, _item, :new, _opts),
    do: socket

  defp apply_action_type(socket, _action_type, _item, _live_action, opts) do
    cond do
      path = opts[:push_patch] -> Phoenix.LiveView.push_patch(socket, path)
      path = opts[:push_navigate] -> Phoenix.LiveView.push_navigate(socket, path)
      true -> socket
    end
  end

  defp send_update_by_conflict(socket, action_user, event, item, :edit, opts) do
    resource = socket.assigns[opts[:target_key]]
    current_id = if resource, do: to_string(resource.id), else: nil

    if current_id == to_string(item.id) do
      form_module = get_form_module(socket, opts)
      Phoenix.LiveView.send_update(form_module, id: item.id, conflict: {event, action_user})
    end

    socket
  end

  defp send_update_by_conflict(socket, _action_user, _event, _item, _live_action, _opts),
    do: socket

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

  defp maybe_assign_resource(socket, target_key, item) do
    current_resource = socket.assigns[target_key]

    if current_resource && to_string(current_resource.id) == to_string(item.id) do
      Phoenix.Component.assign(socket, target_key, item)
    else
      socket
    end
  end

  defp process_empty_selection(acc, field, default_value) do
    empty_key = "#{field}_empty_selection"

    case {Map.has_key?(acc, field), Map.has_key?(acc, empty_key)} do
      {false, true} -> Map.put(acc, field, default_value)
      _ -> acc
    end
  end
end
