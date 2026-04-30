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
  def changeset(post, attrs, current_user, selected_board_metadata) do
    post
    |> cast(attrs, [:title, :content, :metadata, :board_id])
    |> put_change(:author_id, Map.get(current_user || %{}, :id))
    |> validate_required([:title, :content, :board_id])
    |> validate_metadata_required(selected_board_metadata["required"] || [])
  end

  defp validate_metadata_required(changeset, fields) do
    metadata = get_field(changeset, :metadata) || %{}

    Enum.reduce(fields, changeset, fn field_name, acc ->
      if Map.get(metadata, field_name) in [nil, ""] do
        add_error(acc, :metadata, "can't be blank",
          validation: :required,
          field: field_name
        )
      else
        acc
      end
    end)
  end
end
