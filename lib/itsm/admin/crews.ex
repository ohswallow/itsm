defmodule Itsm.Admin.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.Crew

  defdelegate broadcast_crew(crew_id, event), to: Itsm.Crews
  defdelegate broadcast_crews(event), to: Itsm.Crews

  defdelegate get_crew!(id), to: Itsm.Crews

  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  defdelegate create_crew(leader, attrs \\ %{}), to: Itsm.Crews

  def update_crew(%Crew{} = crew, attrs) do
    crew
    |> Crew.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        crew = Repo.preload(crew, [:leader, :users])
        Itsm.Utils.broadcast(:crew, {:update_crew, crew})
        Itsm.Utils.broadcasts(:crews, {:update_crew, crew})

        {:ok, crew}

      {:error, _} = error ->
        error
    end
  end

  def delete_crew(%Crew{} = crew) do
    Repo.delete(crew)
    |> case do
      {:ok, deleted_crew} ->
        Itsm.Utils.broadcast(:crew, {:update_crew, crew})
        Itsm.Utils.broadcasts(:crews, {:update_crew, crew})
        {:ok, deleted_crew}

      {:error, _} = error ->
        error
    end
  end

  def preload_leader(%Crew{} = crew) do
    crew |> Repo.preload(:leader)
  end

  def get_crew_options() do
    Crew
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end
end
