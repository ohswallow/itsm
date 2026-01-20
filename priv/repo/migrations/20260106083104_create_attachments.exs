defmodule Itsm.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :local_path, :string
      # add :content_type, :string
      add :file_type, :string
      add :byte_size, :integer

      # Request와 연결 (삭제 시 파일 정보도 삭제되도록 on_delete: :delete_all)
      # 다형성 컬럼으로 대체 ('26.01.06)
      # add :request_id, references(:requests, type: :binary_id, on_delete: :delete_all)

      # 예: "Request", "Comment" 등
      add :resource_type, :string, null: false
      # 해당 테이블의 UUID
      add :resource_id, :binary_id, null: false

      timestamps(type: :utc_datetime)
    end

    # 검색 속도를 위해 복합 인덱스 생성
    create index(:attachments, [:resource_type, :resource_id])
  end
end
