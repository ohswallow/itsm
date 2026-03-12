defmodule Itsm.OsInstances.OsInstance do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "os_instances" do
    field :os_type, :string
    field :os_version, :string
    field :ip, :string
    field :cpu_core, :integer
    field :memory_gb, :integer
    # field :asset_id, :binary_id
    # field :crew_id, :binary_id

    belongs_to :asset, Itsm.Assets.Asset, type: :binary_id
    belongs_to :crew, Itsm.Crews.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(os_instance, attrs) do
    os_instance
    |> cast(attrs, [:ip, :os_type, :os_version, :cpu_core, :memory_gb, :asset_id, :crew_id])
    |> validate_required([:ip, :os_type, :os_version, :cpu_core, :memory_gb, :asset_id, :crew_id])
  end

  defimpl Itsm.Assets.ResourceCardData, for: Itsm.OsInstances.OsInstance do
    def to_card_item(os) do
      %{
        name: os.os_type,
        badge: os.os_version,
        details: [
          {"IP Address", os.ip},
          {"CPU Core", "#{os.cpu_core} Cores"},
          {"Memory", "#{os.memory_gb} GB"}
        ]
      }
    end
  end
end
