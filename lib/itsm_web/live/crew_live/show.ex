defmodule ItsmWeb.CrewLive.Show do
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
      Crews.subscribe_crews()
    end

    crew =
      Crews.get_crew!(id)
      |> Crews.with_assoc([:leader, :users])

    {:noreply,
     socket
     |> assign(:page_title, "Show Crew")
     |> assign(:crew, crew)
     |> assign(:show_member_modal, false)
     |> stream(:users, Crews.list_regular_users(crew))}
  end

  def handle_event("switch_leader", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    leader = Accounts.get_user!(user_id)

    switch_leader(socket, crew, leader, current_user)
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    target_user = Accounts.get_user!(user_id)

    case Crews.delete_user(crew, target_user, current_user) do
      {:ok, _crew} ->
        msg =
          if current_user == target_user,
            do: "You have left the crew",
            else: "Member removed successfully"

        {:noreply, put_flash(socket, :info, msg)}

      {:error, step} ->
        {:noreply, put_flash(socket, :error, LiveUtil.translate_error(step, :crew))}
    end
  end

  def handle_event("show_member_modal", _params, socket) do
    %{crew: crew, current_user: current_user} = socket.assigns

    # 리더가 없을경우 현재 로그인 사람 리더가 됨
    if Enum.empty?(crew.users) and crew.leader in ["", nil] do
      switch_leader(socket, crew, current_user, current_user)
    else
      {:noreply, assign(socket, :show_member_modal, true)}
    end
  end

  # 리더 변경시 각 버튼의 권한이 달라지므로 전체 stream 전체 reset 처리
  def handle_info({:crew, {:leader_changed, %{id: crew_id}}}, socket) do
    crew =
      Crews.get_crew!(crew_id)
      |> Crews.with_assoc([:leader, :users])

    socket =
      socket
      |> assign(:show_member_modal, false)
      |> assign(:crew, crew)
      |> stream(:users, Crews.list_regular_users(crew), reset: true)

    {:noreply, socket}
  end

  def handle_info({:crew, {:add_users, add_users}}, socket) do
    %{crew: crew} = socket.assigns
    crew = Crews.with_assoc(crew, :leader)

    socket =
      add_users
      |> List.delete(crew.leader)
      |> Enum.reduce(socket, fn user, acc ->
        stream_insert(acc, :users, user, at: 0)
      end)
      |> assign(:show_member_modal, false)

    {:noreply, socket}
  end

  def handle_info({:crew, {:delete_user, removed_user}}, socket) do
    {:noreply,
     socket
     |> assign(:show_member_modal, false)
     |> stream_delete(:users, removed_user)}
  end

  def handle_info({:crews, {:update_crew, update_crew}}, socket) do
    %{crew: crew} = socket.assigns

    if(crew.id == update_crew.id) do
      update_crew = Crews.with_assoc(update_crew, [:leader, :users])
      {:noreply, assign(socket, :crew, update_crew)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:crews, {:delete_crew, deleted_crew}}, socket) do
    %{crew: crew, back_path: back_path} = socket.assigns

    if(crew.id == deleted_crew.id) do
      {:noreply,
       socket
       |> put_flash("info", "The crew has been deleted")
       |> push_navigate(to: back_path)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({ItsmWeb.SearchUsersDialog, :users_selected, user_ids}, socket) do
    %{crew: crew} = socket.assigns

    crew =
      Crews.get_crew!(crew.id)
      |> Crews.with_assoc([:leader, :users])

    users = Accounts.get_users(user_ids)

    case Crews.add_users(crew, users) do
      {:ok, _crew} ->
        {:noreply, put_flash(socket, :info, "Members added successfully")}

      {:error, step} ->
        {:noreply, put_flash(socket, :error, LiveUtil.translate_error(step, :crew))}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp switch_leader(socket, crew, leader, current_user) do
    case Crews.switch_leader(crew, leader, current_user) do
      {:ok, _crew} ->
        {:noreply, put_flash(socket, :info, "Leader changed successfully")}

      {:error, step} ->
        {:noreply, put_flash(socket, :error, LiveUtil.translate_error(step, :crew))}
    end
  end
end
