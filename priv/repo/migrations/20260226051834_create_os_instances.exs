defmodule Itsm.Repo.Migrations.CreateOsInstances do
  use Ecto.Migration

  def change do
    create table(:os_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ip, :string
      add :os_type, :string
      add :os_version, :string
      add :cpu_core, :integer
      add :memory_gb, :integer
      add :asset_id, references(:assets, on_delete: :nothing, type: :binary_id)
      add :crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:os_instances, [:asset_id])
    create index(:os_instances, [:crew_id])
  end
end
