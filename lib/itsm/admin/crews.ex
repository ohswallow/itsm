defmodule Itsm.Admin.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.Crew

  defdelegate broadcast_crew(crew_id, event), to: Itsm.Crews
  defdelegate broadcast_crews(event), to: Itsm.Crews

  defdelegate get_crew!(id), to: Itsm.Crews

  def list_crews do
    Repo.all(Crew)
    |> Repo.preload(:leader)
  end

  defdelegate change_crew(crew, attrs \\ %{}), to: Itsm.Crews

  defdelegate create_crew(leader, attrs \\ %{}), to: Itsm.Crews

  def update_crew(%Crew{} = crew, attrs) do
    crew
    |> Crew.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        # Preload 및 Broadcast
        crew = Repo.preload(crew, [:leader, :users])
        broadcast_crew(crew.id, {:update_crew, crew})
        broadcast_crews({:update_crew, crew})
        {:ok, crew}

      {:error, _} = error ->
        error
    end
  end

  def delete_crew(%Crew{} = crew) do
    Repo.delete(crew)
    |> case do
      {:ok, deleted_crew} ->
        broadcast_crews({:delete_crew, deleted_crew})
        {:ok, deleted_crew}

      {:error, _} = error ->
        error
    end
  end
end
