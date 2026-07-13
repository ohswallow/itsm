defmodule Itsm.Scim.ScimGroupReference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "scim_group_references" do
    field :scim_group_id, :binary_id, primary_key: true
    field :scim_user_id, :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:scim_group_id, :scim_user_id])
    |> validate_required([:scim_group_id, :scim_user_id])
  end
end
