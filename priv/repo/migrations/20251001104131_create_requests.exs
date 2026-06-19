defmodule Itsm.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :env, :string
      add :due_date, :utc_datetime
      add :status, :string
      add :common_k_create_vms, :map
      add :bank_k_resize_vms, :map

      add :requestor_name, :string
      add :requestor_id, references(:users, on_delete: :nothing, type: :binary_id)

      add :category_id, references(:categories, type: :bigint, on_delete: :delete_all),
        null: false

      add :assignee_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
      add :requestor_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:requests, [:category_id])
  end
end
