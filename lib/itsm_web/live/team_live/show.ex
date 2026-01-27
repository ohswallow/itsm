defmodule ItsmWeb.TeamLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Team
  alias Itsm.Members

  def mount(params, _session, socket) do
    back_path = params["return_to"] || ~p"/crews"

    {:ok, assign(socket, :back_path, back_path)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if connected?(socket) do
      Crews.subscribe_crew(id)
    end

    crew = Crews.get_crew_for_show!(id)

    case Team.reassign_leader(crew) do
      {:ok, crew} ->
        {:noreply,
         socket
         |> assign(:page_title, "Show Crew")
         |> assign(:crew, crew)}

      {:error, _message} ->
        # 멤버 아무도 없으면 crew 삭제
        # Crews.delete_crew(crew)

        {:noreply,
         socket
         |> put_flash(:warning, "No members available in this crew")
         |> push_navigate(to: ~p"/crews", replace: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@crew.name}
      <:subtitle>{@crew.description}</:subtitle>
       <%!-- 리더만 멤버추가 가능 --%>
      <:actions :if={@current_user.id == @crew.leader_id or @current_user.role == :admin}>
        <.link patch={~p"/crews/#{@crew}/member"} phx-click={JS.push_focus()}>
          <.button>Add Member</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-6 mb-6 p-6 space-y-6">
      <div class="space-y-3">
        <h3 class="text-sm font-bold text-gray-700">Leader</h3>
        
        <div id="leader-info" phx-update="replace" class="flex items-center py-2">
          <div class="flex items-center gap-3">
            <div>
              <p class="text-sm text-gray-900">
                <%!-- 리더가 없을때의 경우를 대비해서 if문으로 --%> {if @crew.leader,
                  do: "#{@crew.leader.display_name} (#{@crew.leader.email})",
                  else: "Loading..."}
              </p>
               <%!-- <p class="text-xs text-gray-500">Updated {@crew.leader.updated_at}</p> --%>
              <p class="text-xs text-gray-500">
                {if @crew.leader, do: "Updated #{@crew.leader.updated_at}", else: ""}
              </p>
            </div>
          </div>
           <%!-- 접속자가 leader일 경우 you 표시 --%>
          <span
            :if={@current_user.id == @crew.leader_id}
            class="ml-12 px-2 py-1 bg-blue-50 text-blue-700 text-xs rounded-full"
          >
            You
          </span>
        </div>
      </div>
       <%!-- leader 외 멤버 더 있을때만 member 표시 --%>
      <div :if={Enum.count(@crew.members) > 1} class="space-y-3">
        <h3 class="text-sm font-bold text-gray-700">Members</h3>
        
        <div class="space-y-1">
          <div
            :for={member <- Enum.reject(@crew.members, &(&1.user_id == @crew.leader_id))}
            class="flex items-center justify-between py-2"
          >
            <div class="flex items-center gap-3">
              <div>
                <p class="text-sm text-gray-900 break-all">
                  {member.user.display_name} ({member.user.email})
                </p>
                
                <p class="text-xs text-gray-500">Added {member.user.inserted_at}</p>
              </div>
               <%!-- 접속한 본인 you 표시 --%>
              <span
                :if={member.user_id == @current_user.id}
                class="ml-12 px-2 py-1 bg-blue-50 text-blue-700 text-xs rounded-full"
              >
                You
              </span>
            </div>
            
            <div class="flex gap-1">
              <%!-- leader 위임 버튼 --%>
              <button
                :if={@current_user.id == @crew.leader_id}
                phx-click="switch_leader"
                phx-value-user-id={member.user_id}
                class="text-gray-400 hover:text-gray-600 px-2 py-1"
                data-confirm="Are you sure you want to change the crew leader?"
              >
                <.icon name="hero-trophy" class="w-4 h-4" />
              </button>
              <button
                :if={@current_user.id == @crew.leader_id or @current_user.id == member.user_id}
                phx-click="remove_member"
                phx-value-user-id={member.user_id}
                class="text-gray-400 hover:text-gray-600 px-2 py-1"
                data-confirm="Are you sure you want to remove the member?"
              >
                <.icon name="hero-x-mark" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
     <%!-- /crews 또는 /crews/all 진입에 따라 다름 --%>
    <.back navigate={@back_path}>Back</.back>

    <.modal
      :if={@live_action == :member}
      id="search-users"
      show
      on_cancel={JS.patch(~p"/crews/#{@crew}")}
    >
      <.live_component
        module={ItsmWeb.SearchUsersDialog}
        id={@crew.id}
        title={@page_title}
        action={@live_action}
        crew={@crew}
        current_user={@current_user}
        parent_pid={self()}
      />
    </.modal>
    """
  end

  def handle_event("switch_leader", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    case Team.switch_leader(crew, user_id, current_user) do
      {:ok, _crew} ->
        {:noreply, put_flash(socket, :info, "Leader changed successfully")}

      # socket =
      #   socket
      #   |> put_flash(:info, "Leader changed successfully")

      # {:noreply, socket}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    # (화면 갱신은 handle_info가 함)
    case Team.remove_member_from_crew(crew, user_id, current_user) do
      {:ok, _crew} ->
        # 본인 탈퇴 처리
        if user_id == current_user.id do
          {:noreply, put_flash(socket, :info, "You have left the crew")}
        else
          # 타인 강퇴 처리
          {:noreply, put_flash(socket, :info, "Member removed successfully")}
        end

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  # 리더 변경, 리더 할당, 멤버 추가, 멤버 삭제 시
  def handle_info({event, crew}, socket)
      # when event in [:leader_changed, :leader_assigned, :member_added] do
      when event in [:leader_changed, :leader_assigned, :member_added, :member_removed] do
    {:noreply, assign(socket, :crew, crew)}
  end

  # def handle_info({:member_removed, _removed_user_id, crew}, socket) do
  #   # %{current_user: current_user} = socket.assigns

  #   {:noreply, assign(socket, :crew, crew)}

  #   # # 본인이 탈퇴한 경우
  #   # if current_user.id == removed_user_id do
  #   #   {
  #   #     :noreply,
  #   #     socket
  #   #     |> put_flash(:info, "You have been removed from the crew")
  #   #     |> assign(:crew, crew)
  #   #   }
  #   # else
  #   #   # 다른 멤버가 삭제된 경우
  #   #   {:noreply, assign(socket, :crew, crew)}
  #   # end
  # end

  # 멤버 추가 다이얼로그에서 선택된 유저들 처리
  def handle_info({ItsmWeb.SearchUsersDialog, :users_selected, users_id}, socket) do
    %{crew: crew} = socket.assigns

    # 이미 존재하는 user인지 확인하고, 없으면 추가
    Enum.each(users_id, fn user_id ->
      # 이미 존재하는지 확인
      existing = Enum.find(crew.members, &(&1.user_id == user_id))
      IO.puts("You selected #{user_id}")

      unless existing do
        # 없으면 추가
        Members.create_member(%{
          "crew_id" => crew.id,
          "user_id" => user_id
        })
      end
    end)

    {
      :noreply,
      socket
      |> put_flash(:info, "Members added successfully")
      |> push_patch(to: ~p"/crews/#{crew}")
      #  |> assign(:crew, crew)
    }
  end
end
