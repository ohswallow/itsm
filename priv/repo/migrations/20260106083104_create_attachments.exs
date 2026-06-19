defmodule Itsm.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :local_path, :string
      add :file_type, :string
      add :byte_size, :integer
      add :status, :string, default: "active", null: false

      # 예: "Request", "Comment" 등
      add :resource_type, :string, null: false
      # 해당 테이블의 UUID
      add :resource_id, :binary_id, null: false
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # 검색 속도를 위해 복합 인덱스 생성
    create index(:attachments, [:resource_type, :resource_id])
  end
end
