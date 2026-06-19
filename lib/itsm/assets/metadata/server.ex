defmodule Itsm.Assets.Metadata.Server do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :os_type, :string
    field :os_version, :string
    field :cpu_cores, :integer
    field :memory_gb, :integer
    field :ip_address, :string
    field :subnet_mask, :string
    field :hostname, :string
    field :kernel_version, :string
  end

  def changeset(server_metadata, attrs) do
    server_metadata
    |> cast(attrs, [
      :os_type,
      :os_version,
      :cpu_cores,
      :memory_gb,
      :ip_address,
      :subnet_mask,
      :hostname,
      :kernel_version
    ])
    |> validate_required([:os_type, :cpu_cores, :memory_gb, :ip_address, :hostname])
    |> validate_number(:cpu_cores, greater_than: 0, message: "CPU 코어는 1개 이상이어야 합니다.")
    |> validate_number(:memory_gb, greater_than: 0, message: "메모리는 1GB 이상이어야 합니다.")
    |> validate_format(:ip_address, ~r/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/,
      message: "올바른 IP 주소 형식이 아닙니다."
    )
  end

  # defp validate_metadata_required(changeset, metadata) do
  #   {types, required} = parse_metadata_specs(metadata)

  #   current_metadata_params =
  #     changeset.params["metadata"] || changeset.changes[:metadata] || %{}

  #   new_errors =
  #     {%{}, types}
  #     |> cast(current_metadata_params, Map.keys(types))
  #     |> validate_required(required)
  #     |> Map.get(:errors)

  #   case new_errors do
  #     [] ->
  #       changeset

  #     _ ->
  #       combined = Keyword.put(changeset.errors, :metadata, new_errors)
  #       %{changeset | errors: combined, valid?: false}
  #   end
  # end
end
