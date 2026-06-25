defmodule Itsm.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @metadata_registry %{
    "서버" => Itsm.Assets.Metadata.Server,
    "네트워크" => Itsm.Assets.Metadata.Network,
    "스토리지" => Itsm.Assets.Metadata.Storage
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "assets" do
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
    # field :service_crew_id, :binary_id
    # field :system_crew_id, :binary_id
    field :metadata, :map
    # embeds_one :metadata, Itsm.Assets.Metadata, on_replace: :update
    field :mapping_value, :string

    many_to_many :relation_assets, Itsm.Assets.Asset,
      join_through: "v_asset_relations",
      join_keys: [asset_a_id: :id, asset_b_id: :id]

    has_one :os_instance, Itsm.OsInstances.OsInstance

    # 추후 추가
    # has_many :db_instances, Itsm.DbInstances.DbInstance
    # has_many :was_instances, Itsm.WasInstances.WasInstance

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
      :system_crew_id,
      :service_crew_id,
      :mapping_value
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
      :service_crew_id,
      :mapping_value
    ])
    |> unique_constraint(:mapping_value, name: :assets_mapping_value_index)
    |> validate_metadata(attrs)
  end

  def metadata_fields_for_category(category) do
    case Map.get(@metadata_registry, category) do
      nil ->
        []

      module ->
        module.__schema__(:fields)
        |> List.delete(:id)
        |> Enum.map(fn field ->
          {field, module.__schema__(:type, field)}
        end)
    end
  end

  def get_metadata_registry, do: @metadata_registry

  def validate_metadata(changeset, attrs) do
    category = get_field(changeset, :category)
    metadata_attrs = Map.get(attrs, "metadata", %{})

    case Map.get(@metadata_registry, category) do
      nil ->
        put_change(changeset, :metadata, %{})

      module ->
        inner_changeset(changeset, module, metadata_attrs)
    end
  end

  defp inner_changeset(changeset, module, metadata_attrs) do
    struct_data = struct(module)
    inner_changeset = module.changeset(struct_data, metadata_attrs)

    if inner_changeset.valid? do
      clean_map =
        inner_changeset
        |> apply_changes()
        |> Map.from_struct()
        |> Map.drop([:id, :__meta__, :__struct__])

      put_change(changeset, :metadata, clean_map)
    else
      combined = Keyword.put(changeset.errors, :metadata, inner_changeset.errors)
      %{changeset | errors: combined, valid?: false}
    end
  end
end
