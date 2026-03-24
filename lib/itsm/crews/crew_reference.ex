defmodule Itsm.Crews.CrewReference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "crew_references" do
    field :resource_type, :string
    field :resource_id, :binary_id

    belongs_to :crew, Itsm.Crews.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(crew_reference, attrs) do
    crew_reference
    |> cast(attrs, [:resource_id, :resource_type, :crew_id])
    |> validate_required([:resource_id, :resource_type, :crew_id])
  end
end
