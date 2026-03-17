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
end
