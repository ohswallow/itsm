defmodule Itsm.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :comment, :string
    # field :user_id, :binary_id
    # field :request_id, :binary_id

    belongs_to :request, Itsm.Service.Request
    belongs_to :user, Itsm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:comment])
    # |> validate_required([:comment])
    |> validate_length(:comment, min: 1, max: 1000)
    |> assoc_constraint(:user)
    |> assoc_constraint(:request)
  end
end
