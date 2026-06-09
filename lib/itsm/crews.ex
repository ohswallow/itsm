defmodule Itsm.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.{Crew, CrewsUsers, CrewReference}
  alias Itsm.Accounts.User
  alias Itsm.Accounts
  alias Itsm.Utils

  @doc """
  메소드 순서 get->preload->read(select)->create->update->delete-> defp
  """
  def get_crew!(id), do: Repo.get!(Crew, id)

  def get_crews(ids) when is_list(ids) do
    Crew
    |> where([u], u.id in ^ids)
    |> Repo.all()
  end

  def get_crew_with_leader_users(id) do
    get_crew!(id)
    |> Repo.preload([:leader, :users])
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

  def list_my_crews_ids(%User{} = user) do
    CrewsUsers
    |> where([cu], cu.user_id == ^user.id)
    |> select([cu], cu.crew_id)
    |> Repo.all()
  end

  def list_regular_users(%Crew{} = crew) do
    List.delete(crew.users, crew.leader)
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

  def list_live_select_crews(%_{id: resource_id} = resource) do
    CrewReference
    |> join(:inner, [r], c in assoc(r, :crew))
    |> where([r], r.resource_type == ^Utils.resource_name(resource))
    |> where([r], r.resource_id == ^resource_id)
    |> select([r, c], %{label: c.name, tag_label: c.name, value: c.id})
    |> Repo.all()
  end

  def list_crew_reference(repo, %_{id: id} = resource) do
    CrewReference
    |> where([r], r.resource_type == ^Utils.resource_name(resource) and r.resource_id == ^id)
    |> repo.all()
  end

  def change_crew(%Crew{} = crew, attrs \\ %{}) do
    Crew.changeset(crew, attrs)
  end

  def create_crew(%User{} = action_user, attrs) do
    Crew.changeset(%Crew{leader: action_user, users: [action_user]}, attrs)
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

  def create_crew_references(%_{id: id} = resource, crews, repo) when is_list(crews) do
    Enum.reduce_while(crews, {:ok, []}, fn crew, {:ok, acc} ->
      %CrewReference{
        resource_type: Utils.resource_name(resource),
        resource_id: id,
        crew: crew
      }
      |> repo.insert()
      |> case do
        {:ok, crew_reference} ->
          {:cont, {:ok, [crew_reference | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  def add_users(%User{} = action_user, %Crew{} = crew, add_user_ids) do
    add_users = Accounts.get_users(add_user_ids)
    crew = Repo.preload(crew, :users)

    new_users =
      (crew.users ++ add_users)
      |> Enum.uniq_by(& &1.id)

    crew
    |> Crew.users_changeset(new_users)
    |> Repo.update()
    |> case do
      {:ok, _crew} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :add_users, {add_users}},
          id: crew.id
        )

        crew = get_crew!(crew.id) |> Repo.preload([:users, :leader])
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :add_users, crew})

        {:ok, add_users}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :add_users}
    end
  end

  def switch_leader(%User{} = action_user, %Crew{} = crew, %User{} = leader) do
    changeset = Crew.leader_changeset(crew, leader)

    with :ok <- ensure_leader(crew, action_user),
         :ok <- ensure_crew(crew, action_user),
         {:ok, crew} <- Repo.update(changeset) do
      crew = Repo.preload(crew, [:leader, :users])
      Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :switch_leader, crew}, id: crew.id)

      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :switch_leader}

      error ->
        error
    end
  end

  def update_crew(%User{} = action_user, %Crew{} = crew, attrs) do
    crew = Repo.preload(crew, :leader)
    changeset = Crew.changeset(crew, attrs)

    with :ok <- ensure_leader(crew, action_user),
         {:ok, crew} <- Repo.update(changeset) do
      crew = Repo.preload(crew, [:leader, :users])
      Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_crew, crew}, id: crew.id)
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :update_crew, changeset}

      error ->
        error
    end
  end

  def delete_crew(%User{} = action_user, %Crew{} = crew) do
    crew = Repo.preload(crew, :leader)

    with :ok <- ensure_leader(crew, action_user),
         {:ok, crew} <- Repo.delete(crew) do
      Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_crew, crew}, id: crew.id)

      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :delete_crew}

      error ->
        error
    end
  end

  def delete_user(%User{} = action_user, %Crew{} = crew, %User{} = target_user) do
    crews_users = Repo.get_by(CrewsUsers, crew_id: crew.id, user_id: target_user.id)

    with :ok <- ensure_delete_auth(crew, target_user, action_user),
         {:ok, _} <- Repo.delete(crews_users) do
      Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_user, {crew, target_user}},
        id: crew.id
      )

      {:ok, target_user}
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
    if Enum.any?(crew.users, &(&1.id == leader.id)), do: :ok, else: {:error, :not_in_crew}
  end

  defp ensure_delete_auth(crew, target_user, user)
       when user == crew.leader or user == target_user,
       do: :ok

  defp ensure_delete_auth(_crew, _target_user, _user), do: {:error, :unauthorized}
end
