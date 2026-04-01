defmodule Itsm.Admin.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.Crew

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
        crew = Repo.preload(crew, [:leader])
        event = :update_crew
        Itsm.Utils.broadcast(Crew, {attrs["current_user"], event, crew})
        Itsm.Utils.broadcasts(Crew, {attrs["current_user"], event, crew})
        {:ok, crew}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_crew(%{"id" => id} = attrs) do
    Repo.delete(get_crew!(id))
    |> case do
      {:ok, crew} ->
        event = :delete_crew
        Itsm.Utils.broadcast(Crew, {attrs["current_user"], event, crew})
        Itsm.Utils.broadcasts(Crew, {attrs["current_user"], event, crew})
        {:ok, crew}

      {:error, changeset} ->
        {:error, changeset}
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
