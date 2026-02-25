defmodule Itsm.Common.CommonCode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Itsm.Repo

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

  def changeset(codes, attrs) do
    codes
    |> cast(attrs, [:group_code, :code, :label, :description, :sort_order, :is_active])
    |> validate_required([:group_code, :code, :label, :is_active])
  end

  def validate_common_codes(changeset, group_field_map) do
    to_check =
      Enum.reduce(group_field_map, [], fn {field, group_code}, acc ->
        if value = get_change(changeset, field) do
          [{group_code, value, field} | acc]
        else
          acc
        end
      end)

    if to_check == [], do: changeset, else: do_batch_validate(changeset, to_check)
  end

  defp do_batch_validate(changeset, to_check) do
    conditions =
      Enum.reduce(to_check, false, fn {g, c, _f}, acc ->
        dynamic([c], (c.group_code == ^g and c.code == ^c) or ^acc)
      end)

    existing_set =
      from(c in __MODULE__,
        where: ^conditions,
        where: c.is_active == true,
        select: {c.group_code, c.code}
      )
      |> Repo.all()
      |> MapSet.new()

    Enum.reduce(to_check, changeset, fn {g, c, f}, acc_changeset ->
      if MapSet.member?(existing_set, {g, c}) do
        acc_changeset
      else
        add_error(acc_changeset, f, "is invalid (code '#{c}' not found in group '#{g}')")
      end
    end)
  end
end
