defmodule Itsm.Assets.AssetRelation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_relations" do
    belongs_to :asset_a, Itsm.Assets.Asset, foreign_key: :asset_a_id, type: :binary_id
    belongs_to :asset_b, Itsm.Assets.Asset, foreign_key: :asset_b_id, type: :binary_id

    timestamps()
  end

  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [:asset_a_id, :asset_b_id])
    |> validate_required([:asset_a_id, :asset_b_id])
    |> validate_self_relation()
    |> enforce_id_order()
    |> unique_constraint([:asset_a_id, :asset_b_id])
  end

  defp validate_self_relation(changeset) do
    a_id = get_field(changeset, :asset_a_id)
    b_id = get_field(changeset, :asset_b_id)

    if a_id && b_id && a_id == b_id do
      add_error(changeset, :asset_b_id, "cannot be connected to itself (same as Asset A)")
    else
      changeset
    end
  end

  defp enforce_id_order(changeset) do
    a_id = get_field(changeset, :asset_a_id)
    b_id = get_field(changeset, :asset_b_id)

    if a_id && b_id && a_id > b_id do
      changeset
      |> put_change(:asset_a_id, b_id)
      |> put_change(:asset_b_id, a_id)
    else
      changeset
    end
  end
end
