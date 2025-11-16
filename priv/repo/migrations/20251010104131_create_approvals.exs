defmodule Itsm.Repo.Migrations.CreateApprovals do
  use Ecto.Migration

  def change do
    create table(:approvals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string
      add :approver_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :approver_name, :string
      add :comment, :text
      # add :approved_at, :utc_datetime
      add :action, :string
      add :request_id, references(:requests, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:approvals, [:request_id])
  end
end
