defmodule Itsm.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.{Crew, CrewsUsers}
  alias Itsm.Accounts.User

  @doc """
  메소드 순서 subscribe->get->preload->read(select)->create->update->delete-> defp
  """
  def subscribe_crew(crew_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crew:#{crew_id}")
  end

  def broadcast_crew(%Crew{id: crew_id}, message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crew:#{crew_id}", {:crew, message})
  end

  def subscribe_crews() do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "crews")
  end

  def broadcast_crews(message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "crews", {:crews, message})
  end

  def get_crew!(id), do: Repo.get!(Crew, id)

  def preload_leader_and_users(%Crew{} = crew) do
    Repo.preload(crew, [:leader, :users])
  end

  def with_assoc(%Crew{} = crew, preloads) do
    Repo.preload(crew, preloads)
  end

  def list_crews do
    Repo.all(Crew)
    |> Repo.preload(:leader)
  end

  def filter_crews(params) do
    Crew
    |> join(:inner, [c], l in assoc(c, :leader))
    |> with_org(params["organization_code"])
    |> search_by(params["keyword"])
    |> preload(:leader)
    |> Repo.all()
  end

  def list_my_crews(%User{} = user) do
    user
    |> Repo.preload(crews: [:leader])
    |> Map.get(:crews)
  end

  def list_regular_users(%Crew{} = crew) do
    List.delete(crew.users, crew.leader)
  end

  def live_select_by_name_user_name(name, %User{id: user_id}) do
    user_crew_ids =
      CrewsUsers
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

  def options_excluding_user(%User{id: user_id}) do
    user_crew_ids =
      CrewsUsers
      |> where([m], m.user_id == ^user_id)
      |> select([m], m.crew_id)

    Crew
    |> where([c], c.id not in subquery(user_crew_ids))
    |> distinct(true)
    |> select([c], {fragment("? || ' ' || coalesce(?, '')", c.name, c.description), c.id})
    |> Repo.all()
  end

  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
  end

  def create_crew(%User{} = leader, attrs \\ %{}) do
    Crew.changeset(%Crew{leader: leader, users: [leader]}, attrs)
    |> Repo.insert()
    |> case do
      {:ok, crew} ->
        crew = Repo.preload(crew, [:leader, :users])
        {:ok, crew}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :create_crew, changeset}
    end
  end

  def add_users(%Crew{} = crew, add_users) when is_list(add_users) do
    crew = Repo.preload(crew, :users)

    new_users =
      (crew.users ++ add_users)
      |> Enum.uniq_by(& &1.id)

    crew
    |> Crew.users_changeset(new_users)
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        Itsm.Utils.broadcast(Crew, {:add_users, add_users})
        Itsm.Utils.broadcasts(Crew, {:add_users, crew})
        {:ok, crew}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :add_users}
    end
  end

  def switch_leader(%Crew{} = crew, %User{} = leader, %User{} = user) do
    changeset = Crew.leader_changeset(crew, leader)

    with :ok <- ensure_leader(crew, user),
         :ok <- ensure_crew(crew, user),
         {:ok, crew} <- Repo.update(changeset) do
      Itsm.Utils.broadcast(Crew, {:leader_changed, crew})
      Itsm.Utils.broadcasts(Crew, {:leader_changed, crew})
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :switch_leader}

      error ->
        error
    end
  end

  def update_crew(%Crew{} = crew, %User{} = user, attrs \\ %{}) do
    crew = Repo.preload(crew, :leader)
    changeset = Crew.changeset(crew, attrs)

    with :ok <- ensure_leader(crew, user),
         {:ok, crew} <- Repo.update(changeset) do
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :update_crew, changeset}

      error ->
        error
    end
  end

  def delete_crew(%Crew{} = crew, %User{} = user) do
    crew = Repo.preload(crew, :leader)

    with :ok <- ensure_leader(crew, user),
         {:ok, crew} <- Repo.delete(crew) do
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :delete_crew}

      error ->
        error
    end
  end

  def delete_user(%Crew{} = crew, %User{} = target_user, %User{} = user) do
    crews_users = Repo.get_by(CrewsUsers, crew_id: crew.id, user_id: target_user.id)

    with :ok <- ensure_delete_auth(crew, target_user, user),
         {:ok, _} <- Repo.delete(crews_users) do
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :delete_user}

      error ->
        error
    end
  end

  defp with_org(query, keyword) when keyword in ["", nil], do: query

  defp with_org(query, organization_code) do
    where(query, [c, l], l.organization_code == ^organization_code)
  end

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword) do
    where(
      query,
      [c, l],
      ilike(c.name, ^"%#{keyword}%") or
        ilike(c.description, ^"%#{keyword}%") or ilike(l.display_name, ^"%#{keyword}%") or
        ilike(l.department, ^"%#{keyword}%")
    )
  end

  defp ensure_leader(crew, user)
  defp ensure_leader(%Crew{users: []}, _user), do: :ok
  defp ensure_leader(%Crew{leader: leader}, _user) when leader in [nil, ""], do: :ok
  defp ensure_leader(%Crew{leader: leader}, %User{} = user) when leader == user, do: :ok
  defp ensure_leader(_crew, _user), do: {:error, :not_leader}

  defp ensure_crew(%Crew{users: []}, _user), do: :ok
  defp ensure_crew(%Crew{leader: leader}, _user) when leader in [nil, ""], do: :ok

  defp ensure_crew(%Crew{} = crew, %User{} = leader) do
    if Enum.member?(crew.users, leader), do: :ok, else: {:error, :not_in_crew}
  end

  defp ensure_delete_auth(crew, target_user, user)
       when user == crew.leader or user == target_user,
       do: :ok

  defp ensure_delete_auth(_crew, _target_user, _user), do: {:error, :unauthorized}
end
