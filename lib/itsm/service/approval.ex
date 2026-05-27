defmodule Itsm.Service.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  alias Itsm.Service.Request

  @status_values [:request, :validation, :assignment, :check, :start, :finish, :confirmation]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "approvals" do
    field :status, Ecto.Enum,
      values: @status_values,
      default: :request

    # 승인/거부
    field :action, Ecto.Enum,
      values: [:approve, :reject],
      default: :approve

    # field :approver_id, :string
    field :approver_name, :string
    # 선택사항
    # field :comment, :string

    # field :request_id, :binary_id

    belongs_to :approver, Itsm.Accounts.User
    belongs_to :request, Request, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  # 이 함수 추가!
  def status_values, do: @status_values

  @doc false
  def changeset(approval, attrs \\ %{}) do
    approval
    |> cast(attrs, [
      :status,
      :approver_name,
      :action,
      :approver_id,
      :request_id
    ])
    |> validate_required([
      :status,
      :approver_name,
      :action,
      :approver_id,
      :request_id
    ])
    |> assoc_constraint(:approver)
    |> assoc_constraint(:request)
  end

  def admin_changeset(approval, attrs) do
    approval
    |> changeset(attrs)
    |> cast(attrs, [:inserted_at])
    |> validate_required([:inserted_at])
  end
end
