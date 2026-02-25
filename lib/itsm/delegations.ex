defmodule Itsm.Delegations do
  @moduledoc """
  The Delegations context.
  """
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Delegations.Delegation
  alias Itsm.Accounts.User

  # ✅ 모든 delegation 리스트 변경사항 구독 (생성, 업데이트 등)
  def subscribe_delegation_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "delegation_list")
  end

  def broadcast_delegation_list(message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "delegation_list", message)
  end

  @doc """
  Returns the list of delegations.

  ## Examples

      iex> list_delegations()
      [%Delegation{}, ...]

  """

  # [함수 헤드] 기본값(date) 선언 : 이 함수는 인자 2개 받고, 2번째는 기본값이 "오늘"
  def list_delegations(user, date \\ Date.utc_today())

  # --------------------------------------------------------
  # 1. Admin일 경우: 모든 부서의 데이터를 다 보여줌 (Join 불필요)
  # --------------------------------------------------------
  def list_delegations(%User{role: "admin"}, date) do
    Delegation
    |> where([d], d.end_date >= ^date)
    |> order_by([d], asc: d.start_date)
    |> Repo.all()
  end

  # --------------------------------------------------------
  # 2. 일반 유저일 경우: 본인 부서(department_code)와 일치하는 것만 보여줌
  # --------------------------------------------------------
  def list_delegations(%User{} = current_user, date) do
    Delegation
    # 1. 'created_by' User 테이블과 Join
    |> join(:inner, [d], u in assoc(d, :created_by))
    # 2. 작성자의 부서 코드가 현재 사용자와 같은지 필터링
    |> where([d, u], u.department_code == ^current_user.department_code)
    # 3. 날짜 필터 / "종료일이 오늘이랑 같거나 미래인 것" = (과거에 끝난건 제외)
    |> where([d], d.end_date >= ^date)
    # 4. 시작일 순서로 정렬
    |> order_by([d], asc: d.start_date)
    |> Repo.all()
  end

  @doc """
  Gets a single delegation.

  Raises `Ecto.NoResultsError` if the Delegation does not exist.

  ## Examples

      iex> get_delegation!(123)
      %Delegation{}

      iex> get_delegation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_delegation!(id), do: Repo.get!(Delegation, id)

  @doc """
  Creates a delegation.

  ## Examples

      iex> create_delegation(%{field: value})
      {:ok, %Delegation{}}

      iex> create_delegation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_delegation(%User{} = current_user, %User{} = delegator, %User{} = delegatee, attrs) do
    # 구조체 기반으로 필드 채우기
    %Delegation{
      created_by: current_user,
      created_by_id: current_user.id,
      created_by_name: current_user.display_name,
      delegator: delegator,
      delegator_id: delegator.id,
      delegator_name: delegator.display_name,
      delegatee: delegatee,
      delegatee_id: delegatee.id,
      delegatee_name: delegatee.display_name
    }
    |> Delegation.changeset(attrs)
    # 의미 단위로 함수 분리 및 파이프라인 연결
    |> validate_delegator_overlap()
    |> validate_delegatee_overlap()
    |> Repo.insert()
    |> broadcast_result()
  end

  # --------------------------------------------------------
  # 검증 로직 분리
  # --------------------------------------------------------

  # 1. 위임자(Delegator) 중복 체크
  defp validate_delegator_overlap(%Ecto.Changeset{valid?: true} = changeset) do
    params = get_overlap_params(changeset)

    case exists_active_delegation?(params.delegator.id, params.start_date, params.end_date) do
      true ->
        add_error(
          changeset,
          :delegator_id,
          "This user is already assigned as a delegate during this period."
        )

      false ->
        changeset
    end
  end

  # 앞 단계에서 이미 valid: false면 패스
  defp validate_delegator_overlap(changeset), do: changeset

  # 2. 수임자(Delegatee) 중복 체크
  defp validate_delegatee_overlap(%Ecto.Changeset{valid?: true} = changeset) do
    params = get_overlap_params(changeset)

    case exists_active_delegation?(params.delegatee.id, params.start_date, params.end_date) do
      true ->
        add_error(
          changeset,
          :delegatee_id,
          "This user is already assigned as a delegate during this period."
        )

      false ->
        changeset
    end
  end

  # 앞 단계에서 이미 valid: false면 패스
  defp validate_delegatee_overlap(changeset), do: changeset

  # 구조체에서 중복 검사에 필요한 필드 추출
  defp get_overlap_params(changeset) do
    %{
      start_date: get_field(changeset, :start_date),
      end_date: get_field(changeset, :end_date),
      delegator: get_field(changeset, :delegator),
      delegatee: get_field(changeset, :delegatee)
    }
  end

  # 위/수임자가 해당 기간(start~end)에 포함된 위임이 존재하는가? (위임 중복 검사)
  defp exists_active_delegation?(nil, _, _), do: false

  defp exists_active_delegation?(user_id, start_date, end_date) do
    query =
      from d in Delegation,
        where: d.delegator_id == ^user_id or d.delegatee_id == ^user_id,
        where: d.start_date <= ^end_date and d.end_date >= ^start_date

    Repo.exists?(query)
  end

  # 결과 처리 및 브로드캐스트 헬퍼 함수
  defp broadcast_result({:ok, delegation}) do
    broadcast_delegation_list({:delegation_created, delegation})
    {:ok, delegation}
  end

  defp broadcast_result({:error, _} = error), do: error

  @doc """
  Updates a delegation.

  ## Examples

      iex> update_delegation(delegation, %{field: new_value})
      {:ok, %Delegation{}}

      iex> update_delegation(delegation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  # 대결등록은 수정 기능이 필요 없어서 주석 처리
  # def update_delegation(%Delegation{} = delegation, attrs) do
  #   delegation
  #   |> Delegation.changeset(attrs)
  #   |> Repo.update()
  # end

  def delete_delegation(%Delegation{} = delegation, %User{} = current_user) do
    # 등록자 본인이거나, 관리자(admin)라면 삭제 허용
    if delegation.created_by_id == current_user.id or current_user.role == "admin" do
      # Repo.delete(delegation)
      delegation
      |> Repo.delete()
      |> case do
        {:ok, delegation} ->
          # 성공 시 브로드캐스트 실행
          broadcast_delegation_list({:delegation_deleted, delegation})
          {:ok, delegation}

        # 실패 시 에러 그대로 반환 (브로드캐스트 안 함)
        {:error, _} = error ->
          error
      end
    else
      # 아닐경우 권한 오류 반환
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking delegation changes.

  ## Examples

      iex> change_delegation(delegation)
      %Ecto.Changeset{data: %Delegation{}}

  """
  def change_delegation(%Delegation{} = delegation, attrs \\ %{}) do
    Delegation.changeset(delegation, attrs)
  end
end
