defmodule Itsm.Repo.Migrations.CreateRolesPermissions do
  use Ecto.Migration

  def change do
    create table(:roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])

    create table(:permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string
      add :role_id, references(:roles, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:permissions, [:role_id])
    create unique_index(:permissions, [:action, :role_id])

    create table(:user_roles, primary_key: false) do
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :role_id, references(:roles, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_roles, [:user_id, :role_id])
  end
end
