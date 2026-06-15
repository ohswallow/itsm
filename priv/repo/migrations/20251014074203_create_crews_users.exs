defmodule Itsm.Repo.Migrations.CreateCrewsUsers do
  use Ecto.Migration

  def change do
    create table(:crews_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:crews_users, [:crew_id])
    create index(:crews_users, [:user_id])
  end
end
