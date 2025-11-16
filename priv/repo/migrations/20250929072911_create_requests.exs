defmodule Itsm.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :env, :string
      add :due_date, :utc_datetime
      add :common_k_create_vms, :map

      add :requestor_id, references(:users, on_delete: :nothing, type: :binary_id)

      add :requestor_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
