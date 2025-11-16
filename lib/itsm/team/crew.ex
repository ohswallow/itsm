defmodule Itsm.Team.Crew do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "crews" do
    field :name, :string
    field :description, :string

    belongs_to :leader, Itsm.Accounts.User, type: :binary_id
    has_many :members, Itsm.Team.Member

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(crew, attrs) do
    crew
    |> cast(attrs, [:name, :description, :leader_id])
    |> validate_required([:name, :description, :leader_id])
    |> unsafe_validate_unique(:name, Itsm.Repo)
    |> unique_constraint(:name)
    |> validate_format(:name, ~r/^[A-Za-z]{5}$/, message: "must be exactly 5 alphabetic letters")
    |> validate_length(:description, min: 5, max: 20)

    # |> unique_constraint(:name)
  end
end
