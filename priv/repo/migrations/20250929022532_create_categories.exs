defmodule Itsm.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    # create table(:categories, primary_key: false) do
    create table(:categories) do
      # add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :affiliate, :string
      add :request_name, :string
      add :group, :string
      add :active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])
  end
end
