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
  alias Ecto.Multi

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
  def switch_leader(%Crew{} = crew, new_leader_id, %User{} = actor) do
    with :ok <- authorize_leader_change(crew, actor),
         :ok <- ensure_new_leader_is_member(crew, new_leader_id),
         {:ok, crew} <- perform_update_leader(crew, new_leader_id) do
      # 업데이트 후 Show용 데이터 재조회 (Preload 등)
      crew = Crews.get_crew_for_show!(crew.id)
      Crews.broadcast_crew(crew.id, {:leader_changed, crew})

      {:ok, crew}
    else
      {:error, _} = error -> error
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
  # 3. 리더 재할당 (Reassign Leader - 배치/퇴사자 대응)
  # -------------------------------------------------------------------
  def reassign_leader(%Crew{} = crew) do
    # 1. 현재 리더가 DB(User 테이블)에 실제로 존재하는지 확인
    # (배치로 User가 삭제되었을 경우를 대비)
    if crew.leader_id && user_exists?(crew.leader_id) do
      {:ok, crew}
    else
      # 리더가 없거나, 리더 ID는 있는데 User 테이블에 없으면 재할당
      assign_new_leader(crew)
    end
  end

  defp user_exists?(user_id) do
    Repo.exists?(from u in User, where: u.id == ^user_id)
  end

  defp assign_new_leader(%Crew{} = crew) do
    # 다음 리더 후보 찾기
    case get_next_available_member(crew.id) do
      nil ->
        {:error, "No members available to be leader"}

      %Member{user_id: new_leader_id} ->
        {:ok, crew} = perform_update_leader(crew, new_leader_id)

        # 재할당 후 브로드캐스트
        crew = Crews.get_crew_for_show!(crew.id)
        Crews.broadcast_crew(crew.id, {:leader_assigned, crew})

        {:ok, crew}
    end
  end

  # 다음 리더 찾기 (User 테이블과 조인하여 '실존하는' 멤버만 선택)
  # Member 테이블엔 있는데 User 테이블엔 없는 유령 회원이 리더가 되는 것을 방지
  defp get_next_available_member(crew_id) do
    Member
    # User가 존재하는 멤버만
    |> join(:inner, [m], u in assoc(m, :user))
    |> where([m, u], m.crew_id == ^crew_id)
    # 가장 오래된 멤버 순
    |> order_by([m, u], asc: m.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  # -------------------------------------------------------------------
  # Helper Functions (Private)
  # -------------------------------------------------------------------

  # 실제 DB 업데이트
  defp perform_update_leader(crew, new_leader_id) do
    crew
    |> Crew.changeset(%{leader_id: new_leader_id})
    |> Repo.update()
  end

  # 권한 확인: 리더 변경 (Admin or Leader)
  defp authorize_leader_change(crew, actor) do
    cond do
      # 관리자 또는 리더 본인일때 허용
      actor.role == "admin" -> :ok
      crew.leader_id == actor.id -> :ok
      true -> {:error, "You don't have permission to change the leader."}
    end
  end

  # 권한 확인: 멤버 삭제 (Admin or Leader or Self)
  defp authorize_member_removal(crew, target_user_id, actor) do
    cond do
      # 관리자
      actor.role == "admin" -> :ok
      # 리더가 멤버 강퇴
      crew.leader_id == actor.id -> :ok
      # 본인이 탈퇴
      target_user_id == actor.id -> :ok
      true -> {:error, "You don't have permission to remove this member."}
    end
  end

  # 유효성 검사: 새 리더가 멤버인지 확인
  defp ensure_new_leader_is_member(crew, new_leader_id) do
    is_member? = Enum.any?(crew.members, fn m -> m.user_id == new_leader_id end)

    if is_member?, do: :ok, else: {:error, "The selected user is not a member of this crew."}
  end
end
