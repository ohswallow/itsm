defmodule Itsm.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :metadata, :map
      add :board_id, references(:boards, on_delete: :nothing, type: :binary_id)
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:board_id])
    create index(:posts, [:author_id])
  end
end
