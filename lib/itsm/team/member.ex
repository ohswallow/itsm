defmodule Itsm.Team.Member do
  use Ecto.Schema
  import Ecto.Changeset

  # @primary_key {:id, :binary_id, autogenerate: true}
  @primary_key false
  @foreign_key_type :binary_id
  schema "members" do
    belongs_to :user, Itsm.Accounts.User, type: :binary_id, primary_key: true
    belongs_to :crew, Itsm.Team.Crew, type: :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:crew_id, :user_id])
    |> validate_required([:crew_id, :user_id])
  end
end
