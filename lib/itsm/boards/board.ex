defmodule Itsm.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "boards" do
    field :name, :string
    field :description, :string
    field :metadata, :map
    field :slug, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(board, attrs) do
    attrs = Itsm.Utils.maybe_parse_json(attrs, :metadata)

    board
    |> cast(attrs, [:name, :slug, :description, :metadata])
    |> validate_required([:name, :slug, :description])
  end
end
