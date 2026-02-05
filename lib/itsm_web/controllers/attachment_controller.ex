defmodule ItsmWeb.AttachmentController do
  use ItsmWeb, :controller
  alias Itsm.Attachments

  def download(conn, %{"id" => id}) do
    case Attachments.get_attachment!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(ItsmWeb.ErrorHTML)
        |> render("404.html")

      attachment ->
        send_download(
          conn,
          {:file, attachment.local_path},
          filename: attachment.filename,
          content_type: attachment.file_type
        )
    end
  end
end
