defmodule Itsm.Repo.Migrations.AddDepartmentToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :department, :string
      add :department_code, :string
    end
  end
end
