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
      add :metadata, :map, default: %{}, null: false

      add :service_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)
      add :system_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:assets, [:name])
    create index(:assets, [:service_crew_id])
    create index(:assets, [:system_crew_id])

    create index(:assets, [:metadata], using: :gin)

    create table(:asset_relations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add(:asset_a_id, references(:assets, type: :uuid, on_delete: :delete_all), null: false)
      add(:asset_b_id, references(:assets, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create unique_index(:asset_relations, [:asset_a_id, :asset_b_id])
    create index(:asset_relations, [:asset_b_id, :asset_a_id])

    create constraint(:asset_relations, :asset_id_order_check, check: "asset_a_id < asset_b_id")

    create table(:assets_shadow, primary_key: false) do
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
      add :metadata, :map, default: %{}, null: false

      add :asset_id, references(:assets, on_delete: :nothing, type: :binary_id)
      add :service_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)
      add :system_crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:assets_shadow, [:asset_id])
    create index(:assets_shadow, [:service_crew_id])
    create index(:assets_shadow, [:system_crew_id])

    create index(:assets_shadow, [:metadata], using: :gin)

    execute(
      """
      CREATE VIEW v_asset_relations AS
      SELECT asset_a_id, asset_b_id FROM asset_relations
      UNION ALL
      SELECT asset_b_id AS asset_a_id, asset_a_id AS asset_b_id FROM asset_relations;
      """,
      """
      DROP VIEW v_asset_relations;
      """
    )
  end
end
