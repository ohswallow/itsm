defmodule ItsmWeb.CrewLive.Show do
  alias Itsm.Accounts
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.CrewsUsers
  alias Itsm.Accounts
  alias ItsmWeb.LiveUtils

  def mount(params, _session, socket) do
    back_path = params["return_to"] || ~p"/crews?menu_id=crews"

    {:ok, assign(socket, :back_path, back_path)}
  end

  def handle_params(%{"id" => id}, _params, socket) do
    crew = Crews.get_crew_with_leader_users(id)

    {:noreply,
     socket
     |> assign(:page_title, "Show Crew")
     |> assign(:crew, crew)
     |> assign(:show_member_modal, false)
     |> stream(:crews_userses, Crews.list_regular_users(crew), reset: true)
     |> Itsm.PubSub.Helper.subscribe(Crews, id: crew.id)}
  end

  def handle_event("switch_leader", %{"user-id" => user_id}, socket) do
    leader = Accounts.get_user!(user_id)

    switch_leader(socket, leader)
  end

  def handle_event("remove_member", %{"user-id" => user_id}, socket) do
    %{crew: crew, current_user: action_user} = socket.assigns

    target_user = Accounts.get_user!(user_id)

    case Crews.delete_crews_users(action_user, crew, target_user) do
      {:ok, crews_users} ->
        msg =
          if action_user == target_user,
            do: "You have left the crew",
            else: "Member removed successfully"

        socket =
          socket
          |> assign(:show_member_modal, false)
          |> stream_delete(:crews_userses, crews_users)
          |> put_flash(:info, msg)

        {:noreply, socket}

      {:error, step} ->
        {:noreply, put_flash(socket, :error, LiveUtils.translate_error(step, :crew))}
    end
  end

  def handle_event("show_member_modal", _params, socket) do
    %{crew: crew, current_user: action_user} = socket.assigns

    # 리더가 없을경우 현재 로그인 사람 리더가 됨
    if Enum.empty?(crew.crews_users) and crew.leader in ["", nil] do
      switch_leader(socket, action_user)
    else
      {:noreply, assign(socket, :show_member_modal, true)}
    end
  end

  def handle_info({ItsmWeb.SearchUsersDialog, :users_selected, user_ids}, socket) do
    %{crew: crew, current_user: action_user} = socket.assigns

    case Crews.add_crews_users(action_user, crew, user_ids) do
      {:ok, crews_userses} ->
        {:noreply,
         stream(socket, :crews_userses, crews_userses)
         |> assign(:show_member_modal, false)
         |> put_flash(:info, "Members added successfully")}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply, put_flash(socket, :error, LiveUtils.translate_error(step, :crew))}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, :switch_leader = event, crew, socket) do
    opts = [
      flash_message:
        gettext("Leader changed by %{action_user}",
          action_user: action_user.display_name
        ),
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, ItsmWeb.LiveUtils.handle_standard_pubsub(socket, action_user, event, crew, opts)}
  end

  defp handle_pubsub(
         _action_user,
         :add_crews_users = _event,
         {_crew, %CrewsUsers{} = crews_userses},
         socket
       ) do
    {:noreply,
     socket
     |> stream(:crews_userses, crews_userses)
     |> assign(:show_member_modal, false)}
  end

  defp handle_pubsub(
         action_user,
         :delete_crews_users = event,
         {_crew, %CrewsUsers{} = crews_users},
         socket
       ) do
    %{back_path: back_path, current_user: user} = socket.assigns

    opts =
      [resource_name: gettext("Member")]
      |> add_back_path(user.id == crews_users.user_id, back_path)

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, crews_users, opts)
     |> stream_delete(:crews_userses, crews_users)
     |> assign(:show_member_modal, false)}
  end

  defp handle_pubsub(action_user, :update_crew = event, update_crew, socket) do
    %{crew: crew} = socket.assigns

    opts = [
      resource_name: gettext("Crew"),
      target_key: :crew
    ]

    if(crew.id == update_crew.id) do
      {:noreply,
       socket
       |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, update_crew, opts)}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(action_user, :delete_crew = event, deleted_crew, socket) do
    %{back_path: back_path} = socket.assigns

    opts = [
      resource_name: gettext("Crew"),
      target_key: :crew,
      push_navigate: [to: back_path]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, deleted_crew, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp switch_leader(socket, leader) do
    %{crew: crew, current_user: action_user} = socket.assigns

    case Crews.switch_leader(action_user, crew, leader) do
      {:ok, crew} ->
        socket =
          socket
          |> assign(:show_member_modal, false)
          |> assign(:crew, crew)
          |> stream(:crews_userses, Crews.list_regular_users(crew), reset: true)
          |> put_flash(:info, "Leader changed successfully")

        {:noreply, socket}

      {:error, step} ->
        {:noreply, put_flash(socket, :error, LiveUtils.translate_error(step, :crew))}
    end
  end

  defp add_back_path(opts, true, back_path), do: Keyword.put(opts, :push_navigate, to: back_path)
  defp add_back_path(opts, false, _back_path), do: opts
end
