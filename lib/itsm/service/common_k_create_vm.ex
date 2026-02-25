defmodule Itsm.Service.CommonKCreateVm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :ip, :string
    field :description, :string
    field :hostname, :string
    # group_code: "운영체제"
    field :os_image, :string
    field :os_version, :string
    field :cpu_memory, :string
  end

  @doc false
  def changeset(common_k_create_vm, attrs) do
    common_k_create_vm
    |> cast(attrs, [:hostname, :os_image, :cpu_memory, :description, :os_version])
    |> validate_required([:hostname, :os_image, :cpu_memory, :description, :os_version])
  end
end
