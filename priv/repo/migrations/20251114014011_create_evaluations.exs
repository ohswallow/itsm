defmodule Itsm.Repo.Migrations.CreateEvaluations do
  use Ecto.Migration

  def change do
    create table(:evaluations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :comment, :text
      add :rating, :float
      add :crew_id, references(:crews, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:evaluations, [:crew_id])
  end
end
