defmodule Itsm.Members do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Team.Member
  alias Itsm.Crews

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
end
