defmodule Itsm.Crews do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Crews.{Crew, CrewsUsers, CrewReference}
  alias Itsm.Accounts.User
  alias Itsm.Utils

  @doc """
  메소드 순서 get->preload->read(select)->create->update->delete-> defp
  """
  def get_crew!(id), do: Repo.get!(Crew, id)

  def with_assoc(%Crew{} = crew, preloads) do
    Repo.preload(crew, preloads)
  end

  def list_crews do
    Repo.all(Crew)
    |> Repo.preload(:leader)
  end

  def list_crew_reference(resource_type, resource_id) do
    CrewReference
    |> where([r], r.resource_type == ^resource_type and r.resource_id == ^resource_id)
    |> Repo.all()
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
        Utils.broadcasts(__MODULE__, {attrs["current_user"], :create_crew, {:crews, crew}})
        {:ok, crew}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :create_crew, changeset}
    end
  end

  def sync_crew_references(resource_type, resource_id, crews_id) when is_list(crews_id) do
    # 1. 기존 reference 삭제
    delete_crew_references(resource_type, resource_id)

    # 2. 새 reference 생성
    Enum.each(crews_id, fn crew_id ->
      create_crew_reference(%{
        resource_type: resource_type,
        resource_id: resource_id,
        crew_id: crew_id
      })
    end)

    :ok
  end

  def sync_references(_resource_type, _resource_id, _), do: :ok

  def add_users(%Crew{} = crew, add_users, %User{} = action_user) when is_list(add_users) do
    crew = Repo.preload(crew, :users)

    new_users =
      (crew.users ++ add_users)
      |> Enum.uniq_by(& &1.id)

    crew
    |> Crew.users_changeset(new_users)
    |> Repo.update()
    |> case do
      {:ok, crew} ->
        Utils.broadcast(__MODULE__, crew, {action_user, :add_users, {:crew, add_users}})
        Utils.broadcasts(__MODULE__, {action_user, :add_users, {:crews, crew}})
        {:ok, crew}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :add_users}
    end
  end

  def switch_leader(%Crew{} = crew, %User{} = leader, %User{} = action_user) do
    changeset = Crew.leader_changeset(crew, leader)

    with :ok <- ensure_leader(crew, action_user),
         :ok <- ensure_crew(crew, action_user),
         {:ok, crew} <- Repo.update(changeset) do
      Utils.broadcast(__MODULE__, crew, {action_user, :switch_leader, {:crew, crew}})
      Utils.broadcasts(__MODULE__, {action_user, :switch_leader, {:crews, crew}})

      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :switch_leader}

      error ->
        error
    end
  end

  def update_crew(%Crew{} = crew, %User{} = action_user, attrs \\ %{}) do
    crew = Repo.preload(crew, :leader)
    changeset = Crew.changeset(crew, attrs)

    with :ok <- ensure_leader(crew, action_user),
         {:ok, crew} <- Repo.update(changeset) do
      Utils.broadcasts(__MODULE__, {action_user, :update_crew, {:crews, crew}})
      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :update_crew, changeset}

      error ->
        error
    end
  end

  def create_crew_reference(attrs) do
    %CrewReference{}
    |> CrewReference.changeset(attrs)
    |> Repo.insert()
  end

  def delete_crew(%Crew{} = crew, %User{} = action_user) do
    crew = Repo.preload(crew, :leader)

    with :ok <- ensure_leader(crew, action_user),
         {:ok, crew} <- Repo.delete(crew) do
      Utils.broadcast(__MODULE__, crew, {action_user, :delete_crew, {:crew, crew}})
      Utils.broadcasts(__MODULE__, {action_user, :delete_crew, {:crews, crew}})

      {:ok, crew}
    else
      {:error, %Ecto.Changeset{} = _changeset} ->
        {:error, :delete_crew}

      error ->
        error
    end
  end

  def delete_user(%Crew{} = crew, %User{} = target_user, %User{} = action_user) do
    crews_users = Repo.get_by(CrewsUsers, crew_id: crew.id, user_id: target_user.id)

    with :ok <- ensure_delete_auth(crew, target_user, action_user),
         {:ok, _} <- Repo.delete(crews_users) do
      Utils.broadcast(__MODULE__, crew, {action_user, :delete_user, {:crew, target_user}})
      Utils.broadcasts(__MODULE__, {action_user, :delete_user, {:crews, crew, target_user}})

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

  defp delete_crew_references(resource_type, resource_id) do
    CrewReference
    |> where([r], r.resource_type == ^resource_type and r.resource_id == ^resource_id)
    |> Repo.delete_all()
  end
end
