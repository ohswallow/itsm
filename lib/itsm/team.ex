defmodule Itsm.Team do
  @moduledoc """
  The Team context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Crews.Reference
  alias Itsm.Accounts.User

  def create_crew(attrs, %User{} = leader) do
    Crew.changeset(%Crew{leader: leader, users: [leader]}, attrs)
    |> Repo.insert()
    # 4. Pub/sub 브로드캐스트 및 결과 반환
    |> case do
      # 중요: %{crew: crew}로 패턴 매칭해서 꺼내야 함
      {:ok, crew} ->
        # 멤버가 추가된 직후라 아직 crew.members에 없을 수 있으므로 preload 필수
        crew = Repo.preload(crew, [:leader, :users])
        Crews.broadcast_crews_list({:crew_created, crew})
        {:ok, crew}

      # Multi 에러 패턴: {:error, 실패한_단계명, changeset, 성공한_데이터들}
      {:error, changeset} ->
        Logger.warning("create_crew failed at #{inspect(changeset.errors)}")
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
