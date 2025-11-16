defmodule Itsm.Repo.Migrations.CreateDelegations do
  use Ecto.Migration

  def change do
    create table(:delegations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :delegator_name, :string
      add :delegatee_name, :string
      add :start_date, :date
      add :end_date, :date
      add :reason, :string
      add :delegator_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :delegatee_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:delegations, [:delegator_id])
    create index(:delegations, [:delegatee_id])
  end
end
