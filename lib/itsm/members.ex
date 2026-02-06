defmodule Itsm.Members do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Team.Member
  alias Itsm.Crews

  def list_members do
    Repo.all(Member)
  end

  def get_member!(id), do: Repo.get!(Member, id)

  def create_member(attrs \\ %{}) do
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, member} ->
        # 멤버 추가 성공 시, 해당 Crew의 모든 구독자에게 알림
        crew = Crews.get_crew_for_show!(member.crew_id)

        Crews.broadcast_crew(crew.id, {:member_added, crew})
        {:ok, member}

      error ->
        error
    end
  end

  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  def change_member(%Member{} = member, attrs \\ %{}) do
    Member.changeset(member, attrs)
  end

  def search_crews_by_member([]), do: []

  def search_crews_by_member(users) do
    users_id = Enum.map(users, & &1.id)

    Member
    |> where([m], m.user_id in ^users_id)
    |> join(:inner, [m], c in assoc(m, :crew))
    |> select([m, c], c)
    |> distinct(true)
    |> Repo.all()
  end
end
