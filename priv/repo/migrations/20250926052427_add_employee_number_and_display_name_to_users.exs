defmodule Itsm.Repo.Migrations.AddEmployeeNumberAndDisplayNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :employee_number, :string
      add :display_name, :string
      add :organization, :string
      add :organization_code, :string
    end
  end
end
