defmodule Itsm.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :slug, :string
      add :description, :text
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end
  end
end
