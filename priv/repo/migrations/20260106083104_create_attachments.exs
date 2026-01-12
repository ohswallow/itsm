defmodule Itsm.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :local_path, :string
      add :content_type, :string
      add :byte_size, :integer

      # Request와 연결 (삭제 시 파일 정보도 삭제되도록 on_delete: :delete_all)
      add :request_id, references(:requests, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end
