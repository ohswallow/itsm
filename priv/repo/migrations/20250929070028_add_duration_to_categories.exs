defmodule Itsm.Repo.Migrations.AddDurationToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :duration, :integer, default: 60
    end
  end
end
