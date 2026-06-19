defmodule Itsm.Assets.Metadata.Storage do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :storage_type, :string
    field :total_capacity_tb, :float
    field :disk_type, :string
    field :raid_level, :string
    field :controller_count, :integer
    field :protocol, :string
  end

  def changeset(storage_metadata, attrs) do
    storage_metadata
    |> cast(attrs, [
      :storage_type,
      :total_capacity_tb,
      :disk_type,
      :raid_level,
      :controller_count,
      :protocol
    ])
    |> validate_required([:storage_type, :total_capacity_tb, :disk_type, :raid_level])
    |> validate_number(:total_capacity_tb, greater_than: 0.0, message: "스토리지 용량은 0TB보다 커야 합니다.")
    |> validate_number(:controller_count,
      greater_than_or_equal_to: 1,
      message: "컨트롤러는 최소 1개 이상이어야 합니다."
    )
  end
end
