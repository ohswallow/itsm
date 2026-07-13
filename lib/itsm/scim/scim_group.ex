defmodule Itsm.Scim.ScimGroup do
  use Ecto.Schema

  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Itsm.Scim.ScimUser

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scim_groups" do
    field :external_id, :string
    field :version, :string
    field :display_name, :string
    field :value, :string
    field :group_type, :string
    field :acvite, :string
    field :description, :string
    field :meta_created, :utc_datetime
    field :meta_last_modified, :utc_datetime

    has_many :group_reference, Itsm.Scim.ScimGroupReference, foreign_key: :scim_group_id

    many_to_many :users, ScimUser, join_through: Itsm.Scim.ScimGroupReference

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(external_id display_name)a
  @optional_fields ~w(external_id version meta_created meta_last_modified value group_type acvite description)a

  def changeset(scim_group, attrs) do
    changeset =
      scim_group
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> unique_constraint(:external_id)
      |> unique_constraint(:display_name)
      |> put_change(:version, Ecto.UUID.autogenerate())

    case attrs[:users] do
      nil -> changeset
      user_attrs -> put_assoc(changeset, :users, resolve_users(user_attrs))
    end
  end

  defp resolve_users(user_attrs) do
    user_ids =
      user_attrs
      |> Enum.map(fn
        %{"id" => id} -> id
        %{id: id} -> id
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    if user_ids == [] do
      []
    else
      Itsm.Scim.ScimUser
      |> where([u], u.id in ^user_ids)
      |> Itsm.Repo.all()
    end
  end
end
