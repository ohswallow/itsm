defmodule Itsm.Repo.Migrations.AddAsigneeCrewToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :assignee_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
      # add :assignee_crew_name, :string
    end
  end
end
