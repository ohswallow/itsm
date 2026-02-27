defmodule Itsm.Team do
  @moduledoc """
  The Team context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Team.Crew
  alias Itsm.Crews
  alias Itsm.Accounts.User
  alias Itsm.Team.Member
  alias Itsm.Team.Reference

  def create_crew(attrs, %User{} = user) do
    Ecto.Multi.new()
    # 1. Crew 생성 (leader_id 명시적 주입)
    |> Ecto.Multi.insert(:crew, fn _ ->
      params = Map.put(attrs, "leader_id", user.id)

      Crew.changeset(%Crew{}, params)
    end)
    # 2. 리더를 멤버로 추가 (앞 단계의 crew 결과 사용)
    |> Ecto.Multi.insert(:leader_as_member, fn %{crew: crew} ->
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
        Crews.broadcast_crews_list({:crew_created, crew})
        {:ok, crew}

      # Multi 에러 패턴: {:error, 실패한_단계명, changeset, 성공한_데이터들}
      {:error, op, changeset, _} ->
        Logger.warning("create_crew failed at #{op}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  # ==================================================
  # Reference 동기화
  # ==================================================
  # 기존 reference 삭제 후 새로 생성 (replace 방식)
  # 사용 예: Team.sync_references(:service_request, request.id, ["crew_id_1", "crew_id_2"])

  @doc """
  주어진 resource_type과 resource_id에 대한 crew reference를 동기화합니다.
  기존 reference를 모두 삭제하고, 새로운 crews_id 리스트로 다시 생성합니다.
  """
  def sync_references(resource_type, resource_id, crews_id) when is_list(crews_id) do
    # 1. 기존 reference 삭제
    delete_references(resource_type, resource_id)

    # 2. 새 reference 생성
    Enum.each(crews_id, fn crew_id ->
      create_reference(%{
        resource_type: resource_type,
        resource_id: resource_id,
        crew_id: crew_id
      })
    end)

    :ok
  end

  def sync_references(_resource_type, _resource_id, _), do: :ok

  defp delete_references(resource_type, resource_id) do
    Reference
    |> where([r], r.resource_type == ^resource_type and r.resource_id == ^resource_id)
    |> Repo.delete_all()
  end

  def list_reference(resource_type, resource_id) do
    Reference
    |> where([r], r.resource_type == ^resource_type and r.resource_id == ^resource_id)
    |> Repo.all()
  end

  def create_reference(attrs) do
    %Reference{}
    |> Reference.changeset(attrs)
    |> Repo.insert()
  end

  # -------------------------------------------------------------------
  # 1. 리더 변경 (Switch Leader)
  # -------------------------------------------------------------------
  def switch_leader(%Crew{} = crew, %User{} = leader, %User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:authorization, fn _repo, _changes ->
      if leader == user, do: {:ok, :authorized}, else: {:error, :unauthorized}
    end)
    |> Ecto.Multi.run(:new_leader_is_crew, fn _repo, _changes ->
      if Enum.member?(crew.users, leader),
        do: {:ok, :authorized},
        else: {:error, "New leader must be a member of the crew."}
    end)
    |> Ecto.Multi.update(:update_crew, Crew.leader_changeset(crew, leader))
    |> Repo.transaction()
    |> case do
      {:ok, crew} ->
        Crews.broadcast_crew(crew.id, {:leader_changed, crew})
        {:ok, crew}

      {error, _} ->
        error
    end
  end

  # -------------------------------------------------------------------
  # 2. 멤버 삭제/탈퇴 (Remove Member)
  # -------------------------------------------------------------------
  def remove_member_from_crew(%Crew{} = crew, target_user_id, %User{} = actor) do
    with :ok <- authorize_member_removal(crew, target_user_id, actor),
         %Member{} = member <- Repo.get_by(Member, crew_id: crew.id, user_id: target_user_id) do
      Repo.delete(member)
      |> case do
        {:ok, _deleted_member} ->
          # 1. 최신 상태 조회
          crew = Crews.get_crew_for_show!(crew.id)

          # 2. 브로드캐스트 (누가 삭제되었는지 target_user_id 포함)
          # broadcast_crew(crew.id, {:member_removed, target_user_id, crew})
          Crews.broadcast_crew(crew.id, {:member_removed, crew})

          # 3. 결과 리턴
          {:ok, crew}

        {:error, _} = error ->
          error
      end
    else
      nil -> {:error, "Member not found"}
      {:error, _} = error -> error
    end
  end

  # -------------------------------------------------------------------
  # Helper Functions (Private)
  # -------------------------------------------------------------------

  # 권한 확인: 리더 변경 (Admin or Leader)
  defp check_authorization(%Crew{leader: leader}, %User{} = user) do
    if leader == user, do: {:ok, :authorized}, else: {:error, :unauthorized}
  end

  defp check_authorization(_crew, _user),
    do: {:error, "You don't have permission to change the leader."}

  defp check_new_leader_is_crew(%Crew{} = crew, %User{} = leader) do
    if Enum.member?(crew.users, leader),
      do: {:ok, :authorized},
      else: {:error, "New leader must be a member of the crew."}
  end

  # 권한 확인: 멤버 삭제 (Admin or Leader or Self)
  defp authorize_member_removal(crew, target_user_id, actor) do
    cond do
      crew.leader_id == actor.id -> :ok
      # 본인이 탈퇴
      target_user_id == actor.id -> :ok
      true -> {:error, "You don't have permission to remove this member."}
    end
  end
end
