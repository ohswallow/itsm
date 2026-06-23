defmodule Itsm.Admin.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Crews.Crew

  def get_crew!(id), do: Repo.get!(Crew, id)

  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_crew(%User{} = action_user, attrs) do
    %Crew{}
    |> Crew.create_changeset(action_user, attrs)
    |> Repo.insert()
    |> case do
      {:ok, crew} ->
        crew = Repo.preload(crew, [:leader, :users])
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_crew, crew})
        {:ok, crew}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :create_crew, changeset}
    end
  end

  def update_crew(%User{} = action_user, %Crew{} = crew, attrs) do
    crew
    |> Crew.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        crew = Repo.preload(crew, [:leader])
        event = :update_crew
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, crew}, id: crew.id)

        {:ok, crew}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_crew(%User{} = action_user, %{"id" => id}) do
    get_crew!(id)
    |> Repo.delete()
    |> case do
      {:ok, crew} ->
        event = :delete_crew
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, crew}, id: crew.id)

        {:ok, crew}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_crew_options() do
    Crew
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end

  def search_live_select_crews(name, %User{} = exclude_user) do
    user_crew_ids =
      CrewsUsers
      |> where([m], m.user_id == ^exclude_user.id)
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
end
