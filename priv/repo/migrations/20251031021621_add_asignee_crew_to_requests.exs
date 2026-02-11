defmodule Itsm.Repo.Migrations.AddAsigneeCrewToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :assignee_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
    end
  end
end
