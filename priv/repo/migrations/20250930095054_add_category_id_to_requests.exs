defmodule Itsm.Repo.Migrations.AddCategoryIdToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :category_id, references(:categories, type: :bigint, on_delete: :delete_all),
        null: false
    end

    create index(:requests, [:category_id])
  end
end
