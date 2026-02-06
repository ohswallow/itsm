defmodule Itsm.Repo.Migrations.AddAssigneeToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :assignee_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :assignee_name, :string
    end
  end
end
