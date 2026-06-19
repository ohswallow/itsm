defmodule Itsm.Service.BankKResizeVm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :hostname, :string
    field :ip, :string
    field :cpu, :string
    field :memory, :string
    field :description, :string
  end

  @doc false
  def changeset(bank_k_resize_vm, attrs \\ %{}) do
    bank_k_resize_vm
    |> cast(attrs, [:hostname, :ip, :cpu, :memory, :description])
    |> validate_required([:hostname, :ip, :cpu, :memory, :description])
  end
end
