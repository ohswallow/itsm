defmodule Itsm.Service.CommonKCreateVm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :ip, :string
    field :service_name, :string
    field :hostname, :string
    # group_code: "운영체제"
    field :os_image, :string
    field :os_version, :string
    # field :cpu_memory, :string
    field :cpu, :integer
    field :memory, :integer
    field :is_dmz_zone, :boolean, default: false
    field :location, :string
  end

  @doc false
  def changeset(common_k_create_vm, attrs) do
    common_k_create_vm
    |> cast(attrs, [
      :hostname,
      :os_image,
      :cpu,
      :memory,
      :service_name,
      :os_version,
      :is_dmz_zone,
      :location
    ])
    |> validate_required([
      :hostname,
      :os_image,
      :cpu,
      :memory,
      :service_name,
      :os_version,
      :is_dmz_zone,
      :location
    ])
  end
end
