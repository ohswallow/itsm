defmodule Itsm.Team do
  @moduledoc """
  The Team context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Team.Crew
  alias Itsm.Accounts.User
  alias Itsm.Team.Member
  alias Itsm.Team.Reference
  alias Ecto.Multi

  # 특정 crew의 변경사항
  def subscribe_crew(crew_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crew:#{crew_id}")
  end

  defp broadcast_crew(crew_id, event) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crew:#{crew_id}", event)
  end

  # 모든 crew의 변경사항
  def subscribe_crews_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crews_list")
  end

  defp broadcast_crews_list(event) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crews_list", event)
  end

  @doc """
  Returns the list of crews.

  ## Examples

      iex> list_crews()
      [%Crew{}, ...]

  """
  def list_crews do
    Repo.all(Crew)
    |> Repo.preload(:leader)
  end

  def filter_crews(filter) do
    Crew
    |> with_type(filter["organization"])
    |> search_by(filter["q"])
    |> Repo.all()
    |> Repo.preload(:leader)
  end

  defp with_type(query, organization)
       when organization in ~w(KB국민은행 KB국민카드 KB캐피탈 KB증권) do
    where(query, organization: ^organization)
  end

  defp with_type(query, _), do: query

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    where(query, [c], ilike(c.name, ^"%#{q}%"))
  end

  # def list_my_crews(%User{id: user_id}) do
  # Crew
  # |> join(:inner, [c], m in Member, on: m.crew_id == c.id)
  # |> where([_c, m], m.user_id == ^user_id)
  # |> preload(:members)
  # |> order_by([c, _m], asc: c.name)
  # |> distinct(true)
  # |> Repo.all()
  # end

  # def list_my_crews(%User{id: user_id}) do
  #   Crew
  #   |> join(:inner, [c], m in Member, on: m.crew_id == c.id)
  #   |> where([_c, m], m.user_id == ^user_id)
  #   |> order_by([c, _m], asc: c.name)
  #   |> distinct([c], c.id)
  #   |> Repo.all()
  # end
  def list_my_crews(%User{} = user) do
    Crew
    |> join(:inner, [c], m in Member, on: m.crew_id == c.id)
    |> where([_c, m], m.user_id == ^user.id)
    |> order_by([c, _m], asc: c.name)
    |> distinct([c], c.id)
    |> Repo.all()
    |> Repo.preload(:leader)
  end

  @doc """
  Gets a single crew.

  Raises `Ecto.NoResultsError` if the Crew does not exist.

  ## Examples

      iex> get_crew!(123)
      %Crew{}

      iex> get_crew!(456)
      ** (Ecto.NoResultsError)

  """
  def get_crew!(id), do: Repo.get!(Crew, id)

  # 뷰에서 필요한 모든 프리로드 조건
  def get_crew_for_show!(id) do
    Repo.get!(Crew, id)
    |> Repo.preload([:leader, members: [:user]])
  end

  @doc """
  Creates a crew.

  ## Examples

      iex> create_crew(%{field: value})
      {:ok, %Crew{}}

      iex> create_crew(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_crew(attrs, %User{} = user) do
    Multi.new()
    # 1. Crew 생성 (leader_id 명시적 주입)
    |> Multi.insert(:crew, fn _ ->
      params = Map.put(attrs, "leader_id", user.id)

      Crew.changeset(%Crew{}, params)
    end)
    # 2. 리더를 멤버로 추가 (앞 단계의 crew 결과 사용)
    |> Multi.insert(:leader_as_member, fn %{crew: crew} ->
      %Member{}
      |> Member.changeset(%{crew_id: crew.id, user_id: user.id})
    end)
    # 3. 트랜잭션 실행
    |> Repo.transaction()
    # 4. Pub/sub 브로드캐스트 및 결과 반환
    |> case do
      # 중요: %{crew: crew}로 패턴 매칭해서 꺼내야 함
      {:ok, %{crew: crew}} ->
        # 멤버가 추가된 직후라 아직 crew.members에 없을 수 있으므로 preload 필수
        crew = Repo.preload(crew, [:leader, members: [:user]])
        broadcast_crews_list({:crew_created, crew})
        {:ok, crew}

      # Multi 에러 패턴: {:error, 실패한_단계명, changeset, 성공한_데이터들}
      {:error, op, changeset, _} ->
        Logger.warning("create_crew failed at #{op}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  @doc """
  Updates a crew.

  ## Examples

      iex> update_crew(crew, %{field: new_value})
      {:ok, %Crew{}}

      iex> update_crew(crew, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_crew(%Crew{} = crew, attrs, %User{} = user) do
    # 등록자 본인이거나, 관리자(admin)라면 삭제 허용
    if crew.leader_id == user.id or user.role == :admin do
      crew
      |> Crew.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated_crew} ->
          # Preload 및 Broadcast
          crew = Repo.preload(updated_crew, [:leader, members: [:user]])
          broadcast_crew(crew.id, {:crew_updated, crew})
          broadcast_crews_list({:crew_updated, crew})
          {:ok, crew}

        {:error, _} = error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Deletes a crew.

  ## Examples

      iex> delete_crew(crew)
      {:ok, %Crew{}}

      iex> delete_crew(crew)
      {:error, %Ecto.Changeset{}}

  """

  # 1. [System/Core] 실제 삭제 로직 (인자 1개)
  # Show LiveView 처럼 시스템이 자동으로 지울 때 사용합니다.
  # 권한 체크를 하지 않고 바로 지웁니다 (Sudo 권한과 비슷)
  def delete_crew(%Crew{} = crew) do
    Repo.delete(crew)
    |> case do
      {:ok, deleted_crew} ->
        # 삭제 성공 시 브로드캐스트는 여기서 한 번만 관리하면 됨
        broadcast_crews_list({:crew_deleted, deleted_crew})
        {:ok, deleted_crew}

      {:error, _} = error ->
        error
    end
  end

  # 2. [User Action] 사용자 요청 래퍼 (인자 2개)
  # Index LiveView 처럼 사용자가 버튼을 눌렀을 때 사용합니다.
  # 권한을 체크한 뒤, 권한이 있으면 위의 1번 함수를 호출합니다.
  def delete_crew(%Crew{} = crew, %User{} = user) do
    if crew.leader_id == user.id or user.role == :admin do
      # 권한 통과! -> 1번 함수(실제 삭제) 호출
      delete_crew(crew)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking crew changes.

  ## Examples

      iex> change_crew(crew)
      %Ecto.Changeset{data: %Crew{}}

  """
  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
  end

  @doc """
  Returns the list of members.

  ## Examples

      iex> list_members()
      [%Member{}, ...]

  """
  def list_members do
    Repo.all(Member)
  end

  @doc """
  Gets a single member.

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Creates a member.

  ## Examples

      iex> create_member(%{field: value})
      {:ok, %Member{}}

      iex> create_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_member(attrs \\ %{}) do
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a member.

  ## Examples

      iex> update_member(member, %{field: new_value})
      {:ok, %Member{}}

      iex> update_member(member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a member.

  ## Examples

      iex> delete_member(member)
      {:ok, %Member{}}

      iex> delete_member(member)
      {:error, %Ecto.Changeset{}}

  """

  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member changes.

  ## Examples

      iex> change_member(member)
      %Ecto.Changeset{data: %Member{}}

  """

  def change_member(%Member{} = member, attrs \\ %{}) do
    Member.changeset(member, attrs)
  end

  def switch_leader(%Crew{} = crew, user_id) do
    crew
    |> Crew.changeset(%{leader_id: user_id})
    |> Repo.update()
    |> case do
      {:ok, _} ->
        crew = get_crew_for_show!(crew.id)
        broadcast_crew(crew.id, {:leader_changed, crew})
        {:ok, crew}

      {:error, _} = error ->
        error
    end
  end

  def remove_member_from_crew(%Crew{} = crew, user_id, current_user_id) do
    # leader 혹은 본인일 경우에만 삭제 가능
    if crew.leader_id == current_user_id or user_id == current_user_id do
      %Member{crew_id: crew.id, user_id: user_id}
      |> Repo.delete()
      |> case do
        {:ok, _} ->
          crew = get_crew_for_show!(crew.id)
          # broadcast_crew_updated({:member_removed, updated_crew})
          broadcast_crew(crew.id, {:member_removed, user_id, crew})
          {:ok, crew}

        {:error, _} = error ->
          error
      end
    else
      {:error, "You don't have permission to remove this member."}
    end
  end

  def reassign_leader(%Crew{} = crew) do
    if crew.leader_id && Repo.get(User, crew.leader_id) do
      {:ok, crew}
    else
      assign_new_leader(crew)
    end
  end

  defp assign_new_leader(%Crew{} = crew) do
    new_leader = get_next_leader(crew)

    case new_leader do
      nil ->
        {:error, "No members available to be leader"}

      %Member{user_id: user_id} ->
        crew =
          crew
          |> Crew.changeset(%{leader_id: user_id})
          |> Repo.update!()
          |> Repo.preload([:leader, members: [:user]])

        # broadcast_crew(crew.id, {:leader_assigned, user_id, crew})
        broadcast_crew(crew.id, {:leader_assigned, crew})
        {:ok, crew}
    end
  end

  defp get_next_leader(%Crew{id: crew_id}) do
    Member
    |> where(crew_id: ^crew_id)
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def search_crews_by_member([]), do: []

  def search_crews_by_member(users) do
    users_id = Enum.map(users, & &1.id)

    Member
    |> where([m], m.user_id in ^users_id)
    |> join(:inner, [m], c in assoc(m, :crew))
    |> select([m, c], c)
    |> distinct(true)
    |> Repo.all()
  end

  def search_crews_by_name(text) do
    Crew
    |> where([c], ilike(c.name, ^"%#{text}%"))
    |> Repo.all()
  end

  def list_reference(reference_type, reference_id) do
    Reference
    |> where([r], r.reference_type == ^reference_type and r.reference_id == ^reference_id)
    |> Repo.all()
  end

  # def delete_reference(resource_type, resource_id) do
  #   Reference
  #   |> where([r], r.reference_type == ^resource_type and r.reference_id == ^resource_id)
  #   |> Repo.delete_all()
  # end

  def create_reference(attrs) do
    %Reference{}
    |> Reference.changeset(attrs)
    |> Repo.insert()
  end
end
