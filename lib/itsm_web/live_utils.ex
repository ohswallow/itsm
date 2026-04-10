defmodule ItsmWeb.LiveUtils do
  @moduledoc """
  ITSM 개발에 필요한 LiveView에서 사용할 Util메소드 정의 합니다.
  """
  require Logger
  alias Phoenix.LiveView

  def translate_step_error(:approval), do: "Approval creation failed"
  def translate_step_error(:attachment), do: "Attachment upload failed"

  def translate_error(reason, scope \\ nil, opt \\ nil)

  def translate_error(:approval, _scope, _opt), do: gettext("Approval creation failed.")
  def translate_error(:attachment, _scope, _opt), do: gettext("Attachment upload failed.")

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

  def translate_error(type, msg, _opt) do
    Logger.error("#{type}: #{msg}")
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

  def consume_attachments(%Phoenix.LiveView.Socket{} = socket, upload_key \\ :attachment) do
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

  def handle_standard_pubsub(socket, action_user, event, item, opts) do
    [action_type | _] = event |> Atom.to_string() |> String.split("_")

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
