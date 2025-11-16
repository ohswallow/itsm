defmodule ItsmWeb.TeamLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Team

  def mount(params, _session, socket) do
    # back 시, /crews 또는 /crews/all 로 가기 위함
    referrer = params["referrer"] || ~p"/crews"
    {:ok, assign(socket, :referrer, referrer)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    if connected?(socket) do
      Team.subscribe_crew(id)
    end

    crew = Team.get_crew_for_show!(id)

    case Team.reassign_leader(crew) do
      {:ok, crew} ->
        {:noreply,
         socket
         |> assign(:page_title, "Show Crew")
         |> assign(:crew, crew)}

      {:error, _message} ->
        # 멤버 아무도 없으면 crew 삭제
        Team.delete_crew(crew)

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
      <:actions :if={@current_user.id == @crew.leader_id}>
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
    <.back navigate={@referrer}>Back to crews</.back>

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
        parent_pid={self()}
        patch={~p"/admin/crews/#{@crew}"}
      />
    </.modal>
    """
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    case Team.remove_member_from_crew(crew, user_id, current_user.id) do
      {:ok, _crew} ->
        # 본인 탈퇴
        if user_id == current_user.id do
          {:noreply,
           socket
           |> put_flash(:info, "You have left the crew")
           |> push_navigate(to: ~p"/crews", replace: true)}

          # 리더가 추방
        else
          {
            :noreply,
            socket
            |> put_flash(:info, "Member removed successfully")
            #  |> assign(:crew, crew)
          }
        end

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("switch_leader", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    if crew.leader_id == current_user.id do
      case Team.switch_leader(crew, user_id) do
        {:ok, _crew} ->
          socket =
            socket
            |> put_flash(:info, "Leader changed successfully")

          {:noreply, socket}

        {:error, message} ->
          {:noreply, put_flash(socket, :error, message)}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to change the leader.")}
    end
  end

  def handle_info({:member_removed, user_id, crew}, socket) do
    %{current_user: current_user} = socket.assigns

    # 본인이 삭제됨 → 페이지에서 튕겨냄
    if current_user.id == user_id do
      {:noreply,
       socket
       |> push_navigate(to: ~p"/crews", replace: true)}
    else
      # 다른 멤버가 삭제됨 → 목록만 갱신
      {:noreply, assign(socket, :crew, crew)}
    end
  end

  def handle_info({:leader_changed, crew}, socket) do
    {:noreply, assign(socket, :crew, crew)}
  end

  def handle_info({:leader_assigned, crew}, socket) do
    {:noreply, assign(socket, :crew, crew)}
  end

  def handle_info({:users_selected, users_id}, socket) do
    %{crew: crew} = socket.assigns

    # 이미 존재하는 user인지 확인하고, 없으면 추가
    Enum.each(users_id, fn user_id ->
      # 이미 존재하는지 확인
      existing = Enum.find(crew.members, &(&1.user_id == user_id))
      IO.puts("You selected #{user_id}")

      unless existing do
        # 없으면 추가
        Team.create_member(%{
          "crew_id" => crew.id,
          "user_id" => user_id
        })
      end
    end)

    crew = Team.get_crew_for_show!(crew.id)

    {:noreply,
     socket
     |> put_flash(:info, "Members added successfully")
     |> push_patch(to: ~p"/crews/#{crew}")
     |> assign(:crew, crew)}
  end
end
