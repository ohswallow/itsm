defmodule Itsm.Repo.Migrations.RenameReferencedCrew do
  use Ecto.Migration

  def change do
    rename table(:references), :reference_id, to: :resource_id
    rename table(:references), :reference_type, to: :resource_type
  end
end
