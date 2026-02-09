defmodule Itsm.Repo.Migrations.RemoveAssigneeFromRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      remove :assignee_id, references(:users, type: :binary_id)
      remove :assignee_name, :string
    end
  end
end
