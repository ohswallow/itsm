defmodule Itsm.Repo.Migrations.CreateScimSchema do
  use Ecto.Migration

  def change do
    create table(:scim_users, primary_key: false) do
      add :id, :binary_id, primary_key: true, doc: "common readOnly"
      add :external_id, :string, null: false, doc: "common readWrite"
      add :version, :string, null: false, doc: "common readOnly"
      add :user_name, :string, null: false, doc: "core readWrite"
      add :name, :map, doc: "core readWrite"
      add :display_name, :string, doc: "core readWrite"
      add :nick_name, :string, doc: "core readWrite"
      add :profile_url, :string, doc: "core readWrite"
      add :title, :string, doc: "core readWrite"
      add :user_type, :string, doc: "core readWrite"
      add :preferred_language, :string, doc: "core readWrite"
      add :locale, :string, doc: "core readWrite"
      add :timezone, :string, doc: "core readWrite"
      add :active, :boolean, null: false, doc: "core readWrite"
      add :password, :string, doc: "core writeOnly"
      add :emails, {:array, :map}, doc: "core readWrite"
      add :phone_numbers, {:array, :map}, doc: "core readWrite"
      add :ims, {:array, :map}, doc: "core readWrite"
      add :photos, {:array, :map}, doc: "core readWrite"
      add :addresses, {:array, :map}, doc: "core readWrite"
      add :entitlements, {:array, :map}, doc: "core readWrite"
      add :roles, {:array, :map}, doc: "core readWrite"
      add :x509_certificates, {:array, :map}, doc: "core readWrite"
      add :employee_number, :string
      add :organization, :string
      add :organization_code, :string
      add :department, :string
      add :department_code, :string
      add :user_status, :string
      add :attributes, {:array, :map}
      add :manager, :map
      add :cost_center, :string
      add :division, :string
      add :site, :string
      add :location, :string
      add :startdate, :string
      add :enddate, :string
      add :meta, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scim_users, [:id])
    create unique_index(:scim_users, [:external_id])
    create unique_index(:scim_users, [:user_name])

    create table(:scim_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true, doc: "common readOnly"
      add :external_id, :string, null: false, doc: "common readWrite"
      add :version, :string, null: false, doc: "common readOnly"
      add :display_name, :string, null: false, doc: "core readWrite"
      add :value, :string
      add :group_type, :string
      add :acvite, :string
      add :description, :string
      add :meta_created, :utc_datetime
      add :meta_last_modified, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scim_groups, [:id])
    create unique_index(:scim_groups, [:external_id])
    create unique_index(:scim_groups, [:display_name])

    create table(:scim_group_references, primary_key: false) do
      add :scim_group_id, references(:scim_groups, type: :uuid, on_delete: :delete_all),
        null: false

      add :scim_user_id, references(:scim_users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scim_group_references, [:scim_group_id, :scim_user_id])

    create index(:scim_group_references, [:scim_user_id])
  end
end
