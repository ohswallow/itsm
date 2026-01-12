defmodule Itsm.Delegations.Delegation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "delegations" do
    field :reason, Ecto.Enum, values: [:vacation, :business_trip, :dispatch, :training, :others]
    field :delegator_name, :string
    field :delegatee_name, :string
    field :created_by_name, :string
    # field :start_date, :utc_datetime
    # field :end_date, :utc_datetime
    field :start_date, :date
    field :end_date, :date
    # field :delegator_id, :binary_id
    # field :delegatee_id, :binary_id

    belongs_to :delegator, Itsm.Accounts.User
    belongs_to :delegatee, Itsm.Accounts.User
    belongs_to :created_by, Itsm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delegation, attrs) do
    delegation
    |> cast(attrs, [
      # :delegator_name,
      # :delegatee_name,
      # :created_by_name,
      :start_date,
      :end_date,
      :reason
      # ,
      # :delegator_id,
      # :delegatee_id,
      # :created_by_id
    ])
    |> validate_required([
      # :delegator_name,
      # :delegatee_name,
      :start_date,
      :end_date,
      :reason
      # ,
      # :delegator_id,
      # :delegatee_id
    ])
    |> validate_delegatee_is_not_delegator()
    |> validate_start_date_not_past()
    |> validate_end_date_not_before_start()
  end

  # 본인에게 위임 불가 검증
  defp validate_delegatee_is_not_delegator(changeset) do
    # get_field는 변경된 값(changes) 또는 기존 값(data)에서 최신 상태를 가져옵니다.
    delegator_id = get_field(changeset, :delegator_id)
    delegatee_id = get_field(changeset, :delegatee_id)

    # 두 ID를 튜플로 묶어서 패턴 매칭
    case {delegator_id, delegatee_id} do
      # 1. 둘 다 존재하고, 값이 같을 때 (when 가드 절 사용) -> 에러
      {id, id} when not is_nil(id) ->
        add_error(changeset, :delegatee_id, "본인에게는 위임할 수 없습니다.")

      # 2. 그 외 모든 경우 (다르거나, 하나가 없거나) -> 통과
      _ ->
        changeset
    end
  end

  # 시작일이 과거 날짜가 아닌지 검증
  defp validate_start_date_not_past(changeset) do
    validate_change(changeset, :start_date, fn :start_date, date ->
      # UTC 고려하여, 하루 여유를 줌
      yesterday_utc = Date.add(Date.utc_today(), -1)

      if Date.compare(date, yesterday_utc) == :lt,
        do: [start_date: "과거 날짜는 선택할 수 없습니다"],
        else: []
    end)
  end

  # 종료일이 시작일 이전이 아닌지 검증
  defp validate_end_date_not_before_start(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "시작일보다 이전일 수 없습니다")
    else
      changeset
    end
  end
end
