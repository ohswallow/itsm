defmodule Itsm.Repo.Migrations.CreateLogTables do
  use Ecto.Migration

  def change do
    create table(:access_logs) do
      add :user_id, :string, null: false
      add :ip_address, :string
      add :path, :string, null: false
      add :action, :string
      add :metadata, :jsonb, default: "{}"

      timestamps(
        type: :utc_datetime,
        updated_at: false,
        default: fragment("timezone('utc', now())")
      )
    end

    create table(:audit_logs) do
      add :table_name, :string, null: false
      add :target_id, :string, null: false
      add :action, :string, null: false
      add :target, :text
      add :result, :jsonb
      add :user_id, :string, null: false
      add :query_time_ms, :float

      timestamps(
        type: :utc_datetime,
        updated_at: false,
        default: fragment("timezone('utc', now())")
      )
    end

    create index(:access_logs, [:user_id, :inserted_at])
    create index(:audit_logs, [:table_name, :target_id])
    create index(:audit_logs, [:user_id])
  end
end
