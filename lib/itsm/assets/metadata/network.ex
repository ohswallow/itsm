defmodule Itsm.Assets.Metadata.Network do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :device_type, :string
    field :total_ports, :integer
    field :bandwidth_gbps, :integer
    field :management_ip, :string
    field :firmware_version, :string
    field :rack_unit, :integer
  end

  def changeset(network_metadata, attrs) do
    network_metadata
    |> cast(attrs, [
      :device_type,
      :total_ports,
      :bandwidth_gbps,
      :management_ip,
      :firmware_version,
      :rack_unit
    ])
    |> validate_required([:device_type, :total_ports, :management_ip])
    |> validate_number(:total_ports, greater_than: 0, message: "포트 수는 1개 이상이어야 합니다.")
    |> validate_number(:rack_unit, greater_than: 0, message: "랙 유닛(U)은 1 이상이어야 합니다.")
    |> validate_format(:management_ip, ~r/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/,
      message: "올바른 IP 주소 형식이 아닙니다."
    )
  end
end
