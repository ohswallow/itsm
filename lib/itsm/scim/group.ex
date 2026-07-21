defmodule Itsm.Scim.Group do
  use Ecto.Schema

  import Ecto.Query, warn: false
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scim_groups" do
    field :external_id, :string
    field :version, :string
    field :display_name, :string
    field :value, :string
    field :group_type, :string
    field :active, :string
    field :description, :string

    has_many :group_reference, Itsm.Scim.GroupReference, foreign_key: :scim_group_id

    many_to_many :members, Itsm.Scim.User,
      join_through: Itsm.Scim.GroupReference,
      on_replace: :delete

    timestamps(inserted_at: :meta_created, updated_at: :meta_last_modified, type: :utc_datetime)
    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(external_id display_name)a
  @optional_fields ~w(external_id version meta_created meta_last_modified value group_type active description)a

  def changeset(scim_group, attrs) do
    changeset =
      scim_group
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> unique_constraint(:external_id)
      |> unique_constraint(:display_name)
      |> put_change(:version, Ecto.UUID.autogenerate())

    case attrs[:members] do
      nil -> changeset |> put_assoc(:members, [])
      member_attrs -> put_assoc(changeset, :members, resolve_members(member_attrs))
    end
  end

  defp resolve_members(member_attrs) do
    member_attrs
    |> Enum.map(fn
      %{"value" => id} -> Ecto.put_meta(%Itsm.Scim.User{id: id}, state: :loaded)
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
