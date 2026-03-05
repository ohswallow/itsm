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
end
