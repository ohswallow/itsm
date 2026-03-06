defmodule ItsmWeb.TeamLive.Show do
  alias Itsm.Accounts
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias ItsmWeb.LiveUtil

  def mount(params, _session, socket) do
    back_path = params["return_to"] || ~p"/crews"

    {:ok, assign(socket, :back_path, back_path)}
  end

  def handle_params(%{"id" => id}, _params, socket) do
    if connected?(socket) do
      Crews.subscribe_crew(id)
    end

    crew =
      Crews.get_crew!(id)
      |> Crews.preload_leader_and_users()

    {:noreply,
     socket
     |> assign(:page_title, "Show Crew")
     |> assign(:crew, crew)
     |> assign(:leader, crew.leader)
     |> assign(:show_member_modal, false)
     |> stream(:users, Crews.list_regular_users(crew))}
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@crew.name}
      <:subtitle>{@crew.description}</:subtitle>
       <%!-- 리더만 멤버추가 가능 --%>
      <:actions :if={@current_user == @leader or Enum.empty?(@crew.users)}>
        <.button phx-click="show_member_modal">Add Member</.button>
      </:actions>
    </.header>

    <div class="mt-6 mb-6 p-6 space-y-6">
      <div class="space-y-3">
        <h3 class="text-sm font-bold text-gray-700">Leader</h3>
        
        <div id="leader-info" phx-update="replace" class="flex items-center py-2">
          <div class="flex items-center gap-3">
            <div>
              <p class="text-sm text-gray-900">
                <%!-- 리더가 없을때의 경우를 대비해서 if문으로 --%> {if @leader,
                  do: "#{@leader.display_name} (#{@leader.email})",
                  else: "Loading..."}
              </p>
               <%!-- <p class="text-xs text-gray-500">Updated {@crew.leader.updated_at}</p> --%>
              <p class="text-xs text-gray-500">
                Updated
                <span
                  id="leader-updated-at"
                  phx-hook="LocalTime.ToLocale"
                  utc-value={if @leader, do: @leader.updated_at, else: ""}
                >
                </span>
              </p>
            </div>
          </div>
           <%!-- 접속자가 leader일 경우 you 표시 --%>
          <span
            :if={@current_user == @leader}
            class="ml-12 px-2 py-1 bg-blue-50 text-blue-700 text-xs rounded-full"
          >
            You
          </span>
        </div>
      </div>
      
      <div class="space-y-3">
        <h3 class="text-sm font-bold text-gray-700">Members</h3>
        
        <div id="members" phx-update="stream" class="space-y-1">
          <div
            :for={{dom_id, user} <- @streams.users}
            id={dom_id}
            class="flex items-center justify-between py-2 transition-all duration-500 animate-in fade-in slide-in-from-top-2"
            phx-remove={JS.transition("duration-300 opacity-0 scale-95")}
          >
            <div class="flex items-center gap-3">
              <div>
                <p class="text-sm text-gray-900 break-all">{user.display_name} ({user.email})</p>
                
                <p class="text-xs text-gray-500">
                  Added
                  <span
                    id={"member-inserted-at-#{user.id}"}
                    phx-hook="LocalTime.ToLocale"
                    utc-value={user.inserted_at}
                  >
                  </span>
                </p>
              </div>
               <%!-- 접속한 본인 you 표시 --%>
              <span
                :if={user == @current_user}
                class="ml-12 px-2 py-1 bg-blue-50 text-blue-700 text-xs rounded-full"
              >
                You
              </span>
            </div>
            
            <div class="flex gap-1">
              <%!-- leader 위임 버튼 --%>
              <button
                :if={@current_user == @leader or @leader in ["", nil]}
                phx-click="switch_leader"
                phx-value-user-id={user.id}
                class="text-gray-400 hover:text-gray-600 px-2 py-1"
                data-confirm="Are you sure you want to change the crew leader?"
              >
                <.icon name="hero-trophy" class="w-4 h-4" />
              </button>
              <button
                :if={@current_user == @leader or @current_user == user}
                phx-click="remove_member"
                phx-value-user-id={user.id}
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
      :if={@show_member_modal}
      id="search-users"
      show
      on_cancel={JS.patch(~p"/crews/#{@crew}")}
    >
      <.live_component
        id="search-users-dialog"
        current_user={@current_user}
        module={ItsmWeb.SearchUsersDialog}
      />
    </.modal>
    """
  end

  def handle_event("switch_leader", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    leader = Accounts.get_user!(user_id)

    switch_leader(socket, crew, leader, current_user)
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    target_user = Accounts.get_user!(user_id)

    case Crews.remove_user_from_crew(crew, target_user, current_user) do
      {:ok, _crew} ->
        msg =
          if current_user == target_user,
            do: "You have left the crew",
            else: "Member removed successfully"

        {:noreply, put_flash(socket, :info, msg)}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply, put_flash(socket, :error, LiveUtil.translate_step_error(step))}
    end
  end

  def handle_event("show_member_modal", _params, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    if Enum.empty?(crew.users) and crew.leader in ["", nil] do
      switch_leader(socket, crew, current_user, current_user)
    else
      {:noreply, assign(socket, :show_member_modal, true)}
    end
  end

  # 리더 변경시 각 버튼의 권한이 달라지므로 전체 stream 전체 reset 처리
  def handle_info({:leader_changed, %{id: crew_id}}, socket) do
    crew =
      Crews.get_crew!(crew_id)
      |> Crews.preload_leader_and_users()

    socket =
      socket
      |> assign(:show_member_modal, false)
      |> assign(:leader, crew.leader)
      |> stream(:users, Crews.list_regular_users(crew), reset: true)

    {:noreply, socket}
  end

  def handle_info({:member_added, add_users}, socket) do
    %{leader: leader} = socket.assigns

    socket =
      add_users
      |> List.delete(leader)
      |> Enum.reduce(socket, fn user, acc ->
        stream_insert(acc, :users, user, at: 0)
      end)
      |> assign(:show_member_modal, false)

    {:noreply, socket}
  end

  def handle_info({:member_removed, removed_user}, socket) do
    IO.inspect("handle_info received:#{inspect(self())} #{:member_removed}")

    {:noreply,
     socket
     |> assign(:show_member_modal, false)
     |> stream_delete(:users, removed_user)}
  end

  # 멤버 추가 다이얼로그에서 선택된 유저들 처리
  def handle_info({ItsmWeb.SearchUsersDialog, :users_selected, user_ids}, socket) do
    %{crew: crew} = socket.assigns

    users = Accounts.get_users(user_ids)

    case Crews.add_member(crew, users) do
      {:ok, _crew} ->
        {:noreply, put_flash(socket, :info, "Members added successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add members")}
    end
  end

  defp switch_leader(socket, crew, leader, current_user) do
    case Crews.switch_leader(crew, leader, current_user) do
      {:ok, _crew} ->
        {:noreply, put_flash(socket, :info, "Leader changed successfully")}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply, put_flash(socket, :error, LiveUtil.translate_step_error(step))}
    end
  end
end
