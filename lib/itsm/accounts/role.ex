defmodule Itsm.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "roles" do
    field :name, :string
    field :description, :string

    has_many :permissions, Itsm.Accounts.Permission
    has_many :user_roles, Itsm.Accounts.UserRole
    many_to_many :users, Itsm.Accounts.User, join_through: "user_roles", on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def admin_changeset(role, attrs) do
    changeset(role, attrs)
    |> cast(attrs, [:inserted_at])
  end
end
