defmodule Itsm.Repo.Migrations.CreateReferences do
  use Ecto.Migration

  def change do
    create table(:references, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :resource_id, :binary_id
      add :resource_type, :string
      add :crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:references, [:resource_type, :resource_id, :crew_id])
  end
end
