defmodule Itsm.Assets.AssetShadow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "assets_shadow" do
    # group_code: "운영_구분"
    field :env, :string
    field :name, :string
    field :description, :string
    # group_code: "장소"
    field :location, :string
    # group_code: "카테고리"
    field :category, :string
    # group_code: "계열사"
    field :affiliate, :string
    # group_code: "지역_유형"
    field :region_type, :string
    # group_code: "인프라_유형"
    field :infra_type, :string
    field :is_dmz_zone, :boolean, default: false

    field :metadata, :map
    field :mapping_value, :string

    belongs_to :asset, Itsm.Assets.Asset, type: :binary_id

    belongs_to :service_crew, Itsm.Crews.Crew, type: :binary_id
    belongs_to :system_crew, Itsm.Crews.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(asset, attrs \\ %{}) do
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
      :asset_id,
      :system_crew_id,
      :service_crew_id,
      :mapping_value
    ])
    |> validate_required([
      :name,
      :description,
      :mapping_value
    ])
    |> unique_constraint(:mapping_value, name: :assets_shadow_mapping_value_index)
    |> Itsm.Assets.Asset.validate_metadata(attrs)
  end
end
