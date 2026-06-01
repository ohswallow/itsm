defmodule Itsm.Attachments.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "attachments" do
    field :filename, :string
    field :local_path, :string
    field :file_type, :string
    field :byte_size, :integer

    field :status, Ecto.Enum, values: [:active, :pending_delete, :deleted], default: :active

    field :resource_type, :string
    field :resource_id, :binary_id

    field :deleted_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attachment, attrs \\ %{}) do
    attachment
    |> cast(attrs, [
      :filename,
      :local_path,
      :file_type,
      :byte_size,
      :resource_type,
      :resource_id,
      :status
    ])
    |> validate_required([:filename, :local_path, :resource_type])
  end

  def delete_changeset(attachment) do
    attachment
    |> change()
    |> put_change(:status, :pending_delete)
    |> put_change(:deleted_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
