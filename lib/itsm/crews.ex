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

  def broadcast_crew(crew_id, event) do
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
    # Leader(User) 테이블과 Inner Join 하고, 'leader'라는 별칭(as)을 붙임
    |> join(:inner, [c], u in assoc(c, :leader), as: :leader)
    # Join된 데이터를 이용해 Preload (쿼리 한 번으로 가져오기 위함)
    |> preload([leader: u], leader: u)
    |> with_org(params["organization_code"])
    |> search_by(params["keyword"])
    |> Repo.all()
  end

  # organization이 있을 때: 'leader' 별칭을 사용하여 User 테이블의 organization 컬럼 조회
  # defp with_organization(query, organization_code) do
  #   #  when organization in ~w(KB국민은행 KB국민카드 KB캐피탈 KB증권) do
  #   where(query, [leader: u], u.organization_code == ^organization_code)
  # end

  # defp with_organization(query, _), do: query

  # [수정] 이름이 아니라 코드로 비교 (u.organization_code)
  defp with_org(query, organization_code)
       when is_binary(organization_code) and organization_code != "" do
    where(query, [leader: u], u.organization_code == ^organization_code)
  end

  defp with_org(query, _), do: query

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  # Crew(c) 이름, Crew(c) 설명, Leader(u) 이름(display_name)으로 검색
  defp search_by(query, keyword) do
    # filter_crews에서 'as: :leader'로 조인했으므로, 여기서 [leader: u]로 접근 가능
    where(
      query,
      [c, leader: u],
      ilike(c.name, ^"%#{keyword}%") or
        ilike(c.description, ^"%#{keyword}%") or ilike(u.display_name, ^"%#{keyword}%") or
        ilike(u.department, ^"%#{keyword}%")
    )
  end

  def list_my_crews(%User{} = user) do
    Crew
    |> join(:inner, [c], m in Member, on: m.crew_id == c.id)
    |> where([_c, m], m.user_id == ^user.id)
    |> order_by([c, _m], asc: c.name)
    |> distinct([c], c.id)
    |> Repo.all()
    |> Repo.preload(:leader)
  end

  def get_crew!(id), do: Repo.get!(Crew, id)

  # 뷰에서 필요한 모든 프리로드 조건
  def get_crew_for_show!(id) do
    Repo.get!(Crew, id)
    |> Repo.preload([:leader, members: [:user]])
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
end
