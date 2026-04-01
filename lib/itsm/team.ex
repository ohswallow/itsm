defmodule Itsm.Team do
  @moduledoc """
  The Team context.
  """
  require Logger

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.Reference

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
    |> case do
      {:ok, reference} ->
        Itsm.Utils.broadcasts(Reference, {attrs["current_user"], :create_reference, reference})
        {:ok, reference}

      {:error, error} ->
        {:error, error}
    end
  end
end
