defmodule Itsm.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :description, :text
      add :affiliate, :string
      add :request_name, :string
      add :group, :string
      add :active, :boolean, default: true, null: false
      add :duration, :integer, default: 60

      add :assignee_crew_id, references(:crews, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])
  end
end
