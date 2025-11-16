defmodule Itsm.Delegations.Delegation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "delegations" do
    field :reason, Ecto.Enum, values: [:vacation, :business_trip, :dispatch, :training, :others]
    field :delegator_name, :string
    field :delegatee_name, :string
    # field :start_date, :utc_datetime
    # field :end_date, :utc_datetime
    field :start_date, :date
    field :end_date, :date
    # field :delegator_id, :binary_id
    # field :delegatee_id, :binary_id

    belongs_to :delegator, Itsm.Accounts.User
    belongs_to :delegatee, Itsm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delegation, attrs) do
    delegation
    |> cast(attrs, [
      :delegator_name,
      :delegatee_name,
      :start_date,
      :end_date,
      :reason,
      :delegator_id,
      :delegatee_id
    ])
    |> validate_required([
      :delegator_name,
      :delegatee_name,
      :start_date,
      :end_date,
      :reason,
      :delegator_id,
      :delegatee_id
    ])
  end
end
