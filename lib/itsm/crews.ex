defmodule Itsm.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Team.Crew
  alias Itsm.Accounts.User
  alias Itsm.Team.Member

  # 특정 crew의 변경사항
  def subscribe_crew(crew_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crew:#{crew_id}")
  end

  def broadcast_crew(%Crew{id: crew_id}, event) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crew:#{crew_id}", event)
  end

  # 모든 crew의 변경사항
  def subscribe_crews_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crews_list")
  end

  def broadcast_crews_list(event) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crews_list", event)
  end

  def list_crews do
    Repo.all(Crew)
    |> Repo.preload(:leader)
  end

  def filter_crews(params) do
    Crew
    |> join(:inner, [c], l in assoc(c, :leader))
    |> with_org(params["organization_code"])
    |> search_by(params["keyword"])
    |> preload(:leader)
    |> Repo.all()
  end

  def list_my_crews(%User{} = user) do
    user
    |> Repo.preload(crews: [:leader])
    |> Map.get(:crews)
  end

  def get_crew!(id), do: Repo.get!(Crew, id)

  def list_regular_users(%Crew{} = crew) do
    List.delete(crew.users, crew.leader)
  end

  def preload_leader_and_users(%Crew{} = crew) do
    Repo.preload(crew, [:leader, :users])
  end

  def live_select_by_name_user_name(name, %User{id: user_id}) do
    user_crew_ids =
      Member
      |> where([m], m.user_id == ^user_id)
      |> select([m], m.crew_id)

    Crew
    |> join(:inner, [c], u in assoc(c, :users))
    |> where([c], c.id not in subquery(user_crew_ids))
    |> where(
      [c, u],
      ilike(c.name, ^"%#{name}%") or
        ilike(c.description, ^"%#{name}%") or
        ilike(u.display_name, ^"%#{name}%")
    )
    |> distinct(true)
    |> select([c], %{
      label: c.name,
      tag_label: c.name,
      value: c.id,
      description: c.description
    })
    |> Repo.all()
  end

  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
  end

  def update_crew(%Crew{} = crew, attrs, %User{} = user) do
    # 등록자 본인이거나, 관리자(admin)라면 삭제 허용
    if crew.leader_id == user.id do
      crew
      |> Crew.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, crew} ->
          # Preload 및 Broadcast
          crew = Repo.preload(crew, [:leader, members: [:user]])
          broadcast_crew(crew, {:crew_updated, crew})
          broadcast_crews_list({:crew_updated, crew})
          {:ok, crew}

        {:error, _} = error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

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
    if crew.leader_id == user.id do
      # 권한 통과! -> 1번 함수(실제 삭제) 호출
      delete_crew(crew)
    else
      {:error, :unauthorized}
    end
  end

  def add_member(%Crew{} = crew, add_users) when is_list(add_users) do
    new_users =
      (crew.users ++ add_users)
      |> Enum.uniq_by(& &1.id)

    crew
    |> Crew.users_changeset(new_users)
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        broadcast_crew(crew, {:member_added, add_users})
        {:ok, crew}

      {:error, _} = error ->
        error
    end
  end

  def switch_leader(%Crew{} = crew, %User{} = leader, %User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:crew_is_auth, fn _repo, _changes ->
      check_is_auth(crew, user)
    end)
    |> Ecto.Multi.run(:crew_new_leader_is_crew, fn _repo, _changes ->
      check_new_leader_is_crew(crew, leader)
    end)
    |> Ecto.Multi.update(:crew_update_leader, Crew.leader_changeset(crew, leader))
    |> Repo.transaction()
    |> case do
      {:ok, %{crew_update_leader: crew}} ->
        broadcast_crew(crew, {:leader_changed, leader})
        {:ok, crew}

      error ->
        error
    end
  end

  def remove_user_from_crew(%Crew{} = crew, %User{} = target_user, %User{} = actor) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:crew_authorize_user_removal, fn _repo, _changes ->
      authorize_user_removal(crew, target_user, actor)
    end)
    |> Ecto.Multi.run(:crew_remove_user, fn repo, _changes ->
      remove_user(repo, crew, target_user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{crew_remove_user: crew}} ->
        broadcast_crew(crew, {:member_removed, target_user})
        {:ok, crew}

      error ->
        error
    end
  end

  defp with_org(query, keyword) when keyword in ["", nil], do: query

  defp with_org(query, organization_code) do
    where(query, [c, l], l.organization_code == ^organization_code)
  end

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword) do
    where(
      query,
      [c, l],
      ilike(c.name, ^"%#{keyword}%") or
        ilike(c.description, ^"%#{keyword}%") or ilike(l.display_name, ^"%#{keyword}%") or
        ilike(l.department, ^"%#{keyword}%")
    )
  end

  defp check_is_auth(%Crew{leader: leader}, _user) when leader in [nil, ""],
    do: {:ok, :authorized}

  defp check_is_auth(%Crew{users: []}, _user), do: {:ok, :authorized}

  defp check_is_auth(%Crew{leader: leader}, %User{} = user) do
    if leader == user, do: {:ok, :authorized}, else: {:error, :unauthorized}
  end

  defp check_new_leader_is_crew(%Crew{leader: leader}, _user) when leader in [nil, ""],
    do: {:ok, :authorized}

  defp check_new_leader_is_crew(%Crew{users: []}, _user), do: {:ok, :authorized}

  defp check_new_leader_is_crew(%Crew{} = crew, %User{} = leader) do
    if Enum.member?(crew.users, leader), do: {:ok, :authorized}, else: {:error, :unauthorized}
  end

  defp remove_user(repo, %Crew{} = crew, %User{} = target_user) do
    repo.get_by(Member, crew_id: crew.id, user_id: target_user.id)
    |> repo.delete()
    |> case do
      {:ok, _} ->
        {:ok, crew}

      {:error, _} = error ->
        error
    end
  end

  defp authorize_user_removal(crew, target_user, user) do
    if user == crew.leader or user == target_user,
      do: {:ok, :authorized},
      else: {:error, :unauthorized}
  end
end
