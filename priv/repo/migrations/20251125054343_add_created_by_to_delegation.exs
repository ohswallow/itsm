defmodule Itsm.Repo.Migrations.AddCreatedByToDelegation do
  use Ecto.Migration

  def change do
    alter table(:delegations) do
      add :created_by_name, :string
      add :created_by_id, references(:users, on_delete: :nothing, type: :binary_id)
    end
  end
end
