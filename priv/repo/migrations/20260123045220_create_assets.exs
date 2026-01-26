defmodule Itsm.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :affiliate, :string
      add :category, :string
      add :region_type, :string
      add :infra_type, :string
      add :env, :string
      add :location, :string
      add :is_dmz_zone, :boolean, default: false, null: false
      add :service_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)
      add :system_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:assets, [:name])
    create index(:assets, [:service_crew_id])
    create index(:assets, [:system_crew_id])
  end
end
