defmodule Itsm.Repo.Migrations.AddRequestorCrewToRequest do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :requestor_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)
    end
  end
end
