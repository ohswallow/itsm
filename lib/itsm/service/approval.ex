defmodule Itsm.Service.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  alias Itsm.Service.Request

  @status_values [:request, :check, :plan, :review, :start, :finish, :verify]

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
    field :comment, :string

    # field :approved_at, :utc_datetime
    # field :request_id, :binary_id

    belongs_to :approver, Itsm.Accounts.User
    belongs_to :request, Request, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  # 이 함수 추가!
  def status_values, do: @status_values

  @doc false
  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [
      :status,
      :approver_name,
      # :approved_at,
      :action
    ])
    |> validate_required([
      :status,
      :approver_name,
      # :approved_at, # 승인 시각은 나중에 설정
      :action
    ])
    |> assoc_constraint(:approver)
    |> assoc_constraint(:request)
  end
end
