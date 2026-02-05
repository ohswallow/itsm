defmodule ItsmWeb.LiveUtil do
  @moduledoc """
  ITSM 개발에 필요한 LiveView에서 사용할 Util메소드 정의 합니다.
  """
  alias Phoenix.LiveView

  def handle_multi_error(step) do
    case step do
      :approval -> "Approval creation failed"
      :attachment -> "Attachment upload failed"
      _ -> "Data processing failed at step: #{step}."
    end
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
