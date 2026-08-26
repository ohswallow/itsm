defmodule Itsm.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "permissions" do
    field :action, :string

    belongs_to :role, Itsm.Accounts.Role, type: :binary_id

    field :act, :string, virtual: true
    field :path, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:action, :role_id, :act, :path])
    |> validate_required([:action, :role_id])
    |> unique_constraint([:action, :role_id])
  end

  def admin_changeset(permission, attrs) do
    changeset(permission, attrs)
    |> cast(attrs, [:inserted_at])
  end
end
