defmodule Itsm.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "user_roles" do
    belongs_to :user, Itsm.Accounts.User, type: :binary_id, primary_key: true
    belongs_to :role, Itsm.Accounts.Role, type: :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> unique_constraint([:user_id, :role_id])
  end
end
