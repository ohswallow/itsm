defmodule Itsm.Crews.CrewsUsers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "crews_users" do
    belongs_to :crew, Itsm.Crews.Crew, type: :binary_id, primary_key: true
    belongs_to :user, Itsm.Accounts.User, type: :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(crews_users, attrs \\ %{}) do
    crews_users
    |> cast(attrs, [:crew_id, :user_id])
    |> validate_required([:crew_id, :user_id])
  end
end
