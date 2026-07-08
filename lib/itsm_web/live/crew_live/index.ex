defmodule ItsmWeb.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Crews.CrewsUsers
  alias ItsmWeb.LiveUtils

  def mount(_params, _session, socket) do
    %{current_scope: current_scope} = socket.assigns

    {:ok,
     socket
     |> assign(:page_title, "My Crews")
     |> stream(:crews, Crews.list_my_crews(current_scope.user), reset: true)
     |> Itsm.PubSub.Helper.subscribe(Crews)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    %{current_scope: current_scope} = socket.assigns
    crew = Crews.get_crew!(id)

    case Crews.delete_crew(current_scope.user, crew) do
      {:ok, crew} ->
        {:noreply,
         socket
         |> stream_delete(:crews, crew)
         |> put_flash(:info, gettext("Crew deleted successfully."))}

      {:error, step} ->
        {:noreply,
         put_flash(socket, :error, LiveUtils.translate_error(step, :crew, "delete_crew"))}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, event, %Crew{} = item, socket)
       when event in [:update_crew, :switch_leader] do
    modify_crew(socket, action_user, event, item)
  end

  defp handle_pubsub(
         action_user,
         :add_crews_users = event,
         {%Crew{} = item, _crews_users},
         socket
       ) do
    modify_crew(socket, action_user, event, item)
  end

  defp handle_pubsub(action_user, :delete_crew = event, %Crew{} = item, socket) do
    opts = [
      resource_name: gettext("Crew"),
      target_key: :crews
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(
         action_user,
         :delete_crews_users = event,
         {%Crew{} = item, %CrewsUsers{} = crews_users},
         socket
       ) do
    %{current_scope: current_scope} = socket.assigns

    if(current_scope.user.id == crews_users.user_id) do
      opts = [resource_name: gettext("Member")]

      {:noreply,
       ItsmWeb.LiveUtils.handle_standard_pubsub(socket, action_user, event, item, opts)
       |> stream_delete(:crews, item)}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(_action_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp modify_crew(socket, action_user, event, %Crew{} = item) do
    %{current_scope: current_scope} = socket.assigns

    if(
      Enum.any?(item.crews_users, &(&1.user_id == current_scope.user.id)) ||
        current_scope.user.id == item.leader.id
    ) do
      opts = [resource_name: get_resource_name(event)]

      {:noreply,
       socket
       |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
       |> stream_insert(:crews, item)}
    else
      {:noreply, socket}
    end
  end

  defp get_resource_name(:update_crew), do: gettext("Crew")
  defp get_resource_name(:add_crews_users), do: gettext("Members")
  defp get_resource_name(:switch_leader), do: gettext("Crew Leader")
end
