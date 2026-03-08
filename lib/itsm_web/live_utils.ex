defmodule ItsmWeb.LiveUtil do
  @moduledoc """
  ITSM 개발에 필요한 LiveView에서 사용할 Util메소드 정의 합니다.
  """
  alias Phoenix.LiveView

  def translate_step_error(:approval), do: "Approval creation failed"
  def translate_step_error(:attachment), do: "Attachment upload failed"
  def translate_step_error(:crew_is_auth), do: "You don't have permission to change the leader."

  def translate_step_error(:crew_new_leader_is_crew),
    do: "New leader must be a member of the crew."

  def translate_step_error(:crew_authorize_user_removal),
    do: "You don't have permission to remove this member."

  def translate_step_error(:crew_update_leader), do: "Leader update failed"
  def translate_step_error(step), do: "Data processing failed at an unknown step. #{step}"

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
end
