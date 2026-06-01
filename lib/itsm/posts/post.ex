defmodule Itsm.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :metadata, :map
    field :title, :string
    field :content, :string
    belongs_to :board, Itsm.Boards.Board, type: :binary_id
    belongs_to :author, Itsm.Accounts.User, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs, action_user, selected_board_metadata) do
    post
    |> cast(attrs, [:title, :content, :metadata, :board_id])
    |> put_change(:author_id, Map.get(action_user || %{}, :id))
    |> validate_required([:title, :content, :board_id])
    |> validate_metadata_required(selected_board_metadata)
  end

  defp validate_metadata_required(changeset, metadata) do
    {types, required} = parse_metadata_specs(metadata)

    current_metadata_params =
      changeset.params["metadata"] || changeset.changes[:metadata] || %{}

    new_errors =
      {%{}, types}
      |> cast(current_metadata_params, Map.keys(types))
      |> validate_required(required)
      |> Map.get(:errors)

    case new_errors do
      [] ->
        changeset

      _ ->
        combined = Keyword.put(changeset.errors, :metadata, new_errors)
        %{changeset | errors: combined, valid?: false}
    end
  end

  defp parse_metadata_specs(metadata) do
    types =
      metadata["fields"]
      |> List.wrap()
      |> Map.new(fn field ->
        key = String.to_atom(field["name"] || "undefined")
        type = String.to_atom(Itsm.Utils.input_type_cast(field["type"]))
        {key, type}
      end)

    required = Enum.map(metadata["required"] || [], &String.to_atom/1)

    {types, required}
  end
end
