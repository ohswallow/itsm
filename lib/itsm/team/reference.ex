defmodule Itsm.Team.Reference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "references" do
    field :reference_id, :binary_id
    # field :reference_type, :string
    field :reference_type, Ecto.Enum,
      values: [:service_request, :change_management, :incident_management]

    # field :crew_id, :binary_id

    belongs_to :crew, Itsm.Team.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reference, attrs) do
    reference
    |> cast(attrs, [:reference_id, :reference_type, :crew_id])
    |> validate_required([:reference_id, :reference_type, :crew_id])
  end
end
