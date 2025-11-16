defmodule Itsm.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members, primary_key: false) do
      add :crew_id, references(:crews, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id),
        primary_key: true

      timestamps(type: :utc_datetime)
    end

    create index(:members, [:crew_id])
    create index(:members, [:user_id])
  end
end
