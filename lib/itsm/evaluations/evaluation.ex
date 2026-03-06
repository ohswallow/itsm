defmodule Itsm.Evaluations.Evaluation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "evaluations" do
    field :comment, :string
    field :rating, :float
    # field :crew_id, :binary_id

    belongs_to :crew, Itsm.Crews.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [:comment, :rating, :crew_id])
    |> validate_required([:comment, :crew_id])
    |> validate_number(:rating,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 5.0
    )
  end
end
