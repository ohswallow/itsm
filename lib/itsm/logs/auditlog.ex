defmodule Itsm.Logs.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :table_name, :string
    field :target_id, :string
    field :action, :string
    field :user_id, :string
    field :query_time_ms, :float

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:table_name, :target_id, :action, :user_id, :query_time_ms])
    |> validate_required([:table_name, :target_id, :user_id])
  end
end
