defmodule Itsm.Repo.Migrations.AddAssigneeCrewToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :assignee_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
    end
  end
end
