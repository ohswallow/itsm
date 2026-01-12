defmodule Itsm.Attachments.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "attachments" do
    field :byte_size, :integer
    field :filename, :string
    field :local_path, :string
    field :content_type, :string

    belongs_to :request, Itsm.Service.Request

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:filename, :local_path, :content_type, :byte_size, :request_id])
    |> validate_required([:filename, :local_path])
  end
end
