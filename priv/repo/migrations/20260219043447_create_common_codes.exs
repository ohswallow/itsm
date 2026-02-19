defmodule Itsm.Repo.Migrations.CreateCommonCodes do
  use Ecto.Migration

  def change do
    create table(:common_codes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_code, :string
      add :code, :string
      add :label, :string
      add :description, :string, null: true
      add :sort_order, :integer, default: 0, null: true
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end
  end
end
