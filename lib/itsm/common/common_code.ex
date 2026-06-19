defmodule Itsm.Common.CommonCode do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "common_codes" do
    field :code, :string
    field :label, :string
    field :description, :string
    field :group_code, :string
    field :sort_order, :integer, default: 0
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  def changeset(codes, attrs \\ %{}) do
    codes
    |> cast(attrs, [:group_code, :code, :label, :description, :sort_order, :is_active])
    |> validate_required([:group_code, :code, :label, :is_active])
  end
end
