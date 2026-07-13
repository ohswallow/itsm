defmodule Itsm.Scim.ScimUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias Itsm.Scim.ScimGroup

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scim_users" do
    field :external_id, :string
    field :version, :string
    field :user_name, :string
    field :name, :map
    field :display_name, :string
    field :nick_name, :string
    field :profile_url, :string
    field :title, :string
    field :user_type, :string
    field :preferred_language, :string
    field :locale, :string
    field :timezone, :string
    field :active, :boolean
    field :password, :string, redact: true
    field :emails, {:array, :map}, default: []
    field :phone_numbers, {:array, :map}, default: []
    field :ims, {:array, :map}, default: []
    field :photos, {:array, :map}, default: []
    field :addresses, {:array, :map}, default: []
    field :entitlements, {:array, :map}, default: []
    field :roles, {:array, :map}, default: []
    field :x509_certificates, {:array, :map}, default: []
    field :employee_number, :string
    field :organization, :string
    field :organization_code, :string
    field :department, :string
    field :department_code, :string
    field :user_status, :string
    field :attributes, {:array, :map}, default: []
    field :manager, :map
    field :cost_center, :string
    field :division, :string
    field :site, :string
    field :location, :string
    field :startdate, :string
    field :enddate, :string
    field :meta, :map

    many_to_many :groups, ScimGroup, join_through: Itsm.Scim.ScimGroupReference

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(external_id user_name)a
  @optional_fields ~w(
    version name display_name nick_name profile_url title user_type
    preferred_language locale timezone active password
    emails phone_numbers ims photos addresses entitlements roles x509_certificates employee_number
    organization organization_code department department_code user_status attributes manager
    cost_center division site location startdate enddate meta
  )a

  def changeset(scim_user, attrs) do
    scim_user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:external_id)
    |> unique_constraint(:user_name)
    |> put_change(:version, Ecto.UUID.autogenerate())
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:password, Pbkdf2.hash_pwd_salt(password))
    else
      changeset
    end
  end
end
