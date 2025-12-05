defmodule Itsm.Delegations do
  @moduledoc """
  The Delegations context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Delegations.Delegation
  alias Itsm.Accounts
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

  # def list_delegations do
  #   Repo.all(Delegation)
  # end

  def list_delegations(date \\ Date.utc_today()) do
    Delegation
    # "종료일이 오늘이랑 같거나 미래인 것" = (과거에 끝난건 제외)
    |> where([d], d.end_date >= ^date)
    # 시작일 순서로 정렬
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
  # def create_delegation(attrs \\ %{}) do
  #   %Delegation{}
  #   |> Delegation.changeset(attrs)
  #   |> Repo.insert()
  # end
  def create_delegation(attrs) do
    # 1. 3명의 이름을 모두 ID 기반으로 조회해서 채워넣음
    attrs =
      attrs
      |> put_name_from_id("delegator_id", "delegator_name")
      |> put_name_from_id("delegatee_id", "delegatee_name")
      |> put_name_from_id("created_by_id", "created_by_name")

    # 디버깅용 로그: 여기서 이름이 들어갔는지 확인
    IO.inspect(attrs, label: "CHECK ATTRS IN create_delegation CONTEXT")

    # 2. Changeset 생성 (아직 DB 저장 안 함)
    changeset = Delegation.changeset(%Delegation{}, attrs)

    # 3. [추가] 중복 기간 검증 (Context 레벨의 유효성 검사)
    #    Changeset이 유효할 때만 DB 검사를 수행합니다.
    changeset =
      if changeset.valid? do
        validate_overlap(changeset)
      else
        changeset
      end

    # 4. 저장 및 PubSub 브로드캐스트 로직 추가
    # Repo.insert(changeset)
    changeset
    |> Repo.insert()
    |> case do
      {:ok, delegation} ->
        # 성공 시 브로드캐스트 실행
        broadcast_delegation_list({:delegation_created, delegation})
        {:ok, delegation}

      # 실패 시 에러 그대로 반환 (브로드캐스트 안 함)
      {:error, _} = error ->
        error
    end
  end

  defp validate_overlap(changeset) do
    start_date = Ecto.Changeset.get_field(changeset, :start_date)
    end_date = Ecto.Changeset.get_field(changeset, :end_date)
    delegator_id = Ecto.Changeset.get_field(changeset, :delegator_id)
    delegatee_id = Ecto.Changeset.get_field(changeset, :delegatee_id)

    cond do
      # 1. "위임자에게 겹치는 위임이 있는가?"
      has_overlapping_delegation?(delegator_id, start_date, end_date) ->
        Ecto.Changeset.add_error(
          changeset,
          :delegator_id,
          "This user is already assigned as a delegate during this period."
        )

      # 2. "수임자에게 겹치는 위임이 있는가?"
      has_overlapping_delegation?(delegatee_id, start_date, end_date) ->
        Ecto.Changeset.add_error(
          changeset,
          :delegatee_id,
          "This user is already assigned as a delegate during this period."
        )

      true ->
        changeset
    end
  end

  # "이 사용자(user_id)가 이 기간(start~end)에 포함된 위임이 존재하는가?"
  defp has_overlapping_delegation?(nil, _, _), do: false

  defp has_overlapping_delegation?(user_id, start_date, end_date) do
    query =
      from d in Delegation,
        where: d.delegator_id == ^user_id or d.delegatee_id == ^user_id,
        where: d.start_date <= ^end_date and d.end_date >= ^start_date

    Repo.exists?(query)
  end

  defp put_name_from_id(attrs, id_key, name_key) do
    id = attrs[id_key]
    name = attrs[name_key]

    # ID는 있는데 이름이 없거나 빈 문자열("")일 때만 -> DB 조회
    if id && id != "" && (is_nil(name) || name == "") do
      case Accounts.get_user!(id) do
        # 유저 없으면 무시
        nil -> attrs
        user -> Map.put(attrs, name_key, user.display_name)
      end
    else
      # 이미 이름이 있거나 ID가 없으면 패스
      attrs
    end
  end

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

  # def delete_delegation(%Delegation{} = delegation) do
  #   Repo.delete(delegation)
  # end

  def delete_delegation(%Delegation{} = delegation, %User{} = current_user) do
    # 등록자 본인이거나, 관리자(admin)라면 삭제 허용
    if delegation.created_by_id == current_user.id or current_user.role == :admin do
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
