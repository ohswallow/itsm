defmodule Itsm.Repo.Migrations.AddCategoryToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :category, :string
    end
  end
end
