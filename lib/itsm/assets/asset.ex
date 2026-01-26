defmodule Itsm.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "assets" do
    field :env, Ecto.Enum, values: [:prod, :stg, :dev, :dr]
    field :name, :string
    field :description, :string
    field :location, Ecto.Enum, values: [:yeouido_it, :gimpo_it, :branch, :head_office]
    field :category, Ecto.Enum, values: [:server, :network, :storage, :hypervisor, :appliance]

    field :affiliate, Ecto.Enum,
      values: [:A0, :B0, :C0, :D0, :FG, :I0, :L0, :M0, :N4, :N1, :S2, :T0, :V0]

    field :region_type, Ecto.Enum, values: [:P_region, :K_region_common, :K_region_bank, :legacy]
    field :infra_type, Ecto.Enum, values: [:on_premise, :aws, :azure, :appliance]
    field :is_dmz_zone, :boolean, default: false
    # field :service_crew_id, :binary_id
    # field :system_crew_id, :binary_id

    belongs_to :service_crew, Itsm.Team.Crew, type: :binary_id, primary_key: true
    belongs_to :system_crew, Itsm.Team.Crew, type: :binary_id, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [
      :name,
      :description,
      :affiliate,
      :category,
      :region_type,
      :infra_type,
      :env,
      :location,
      :is_dmz_zone,
      :system_crew_id,
      :service_crew_id
    ])
    |> validate_required([
      :name,
      :description,
      :affiliate,
      :category,
      :region_type,
      :infra_type,
      :env,
      :location,
      :is_dmz_zone,
      :system_crew_id,
      :service_crew_id
    ])
    |> unique_constraint(:name)
  end
end
