defmodule Itsm.Logs.AccessLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "access_logs" do
    field :user_id, :string
    field :ip_address, :string
    field :path, :string
    field :action, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(access_log, attrs \\ %{}) do
    access_log
    |> cast(attrs, [:user_id, :ip_address, :path, :action, :metadata])
    |> truncate_path()
  end

  defp truncate_path(changeset) do
    case get_change(changeset, :path) do
      nil ->
        changeset

      path ->
        truncated = String.slice(path, 0, 255)
        put_change(changeset, :path, truncated)
    end
  end
end
