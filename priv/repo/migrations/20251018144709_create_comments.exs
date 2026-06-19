defmodule Itsm.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :comment, :text
      add :user_id, references(:users, on_delete: :nilify_all, type: :binary_id)
      # add :request_id, references(:requests, on_delete: :nilify_all, type: :binary_id)
      # 어떤 모델에 달린 댓글인지
      add :resource_type, :string, null: false
      add :resource_id, :binary_id, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:resource_type, :resource_id])
    # create index(:comments, [:user_id])
    # create index(:comments, [:request_id])
  end
end
