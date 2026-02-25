defmodule Itsm.Repo.Migrations.CreateCrews do
  use Ecto.Migration

  def change do
    create table(:crews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :leader_id, references(:users, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:crews, [:name])
    create index(:crews, [:leader_id])
  end
end
