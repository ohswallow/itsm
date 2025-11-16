defmodule Itsm.Repo.Migrations.AddStatusToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :status, :string
    end
  end
end
