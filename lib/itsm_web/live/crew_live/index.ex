defmodule ItsmWeb.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Accounts.User
  alias ItsmWeb.LiveUtils

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:crews, []) |> Itsm.PubSub.Helper.subscribe(Crews)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    %{current_user: current_user} = socket.assigns

    socket
    |> assign(:page_title, "My Crews")
    |> stream(:crews, Crews.list_my_crews(current_user), reset: true)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Crew")
    |> assign(:crew, Crews.get_crew!(id))
  end

  def handle_event("delete", %{"id" => id}, socket) do
    %{current_user: action_user} = socket.assigns
    crew = Crews.get_crew!(id)

    case Crews.delete_crew(action_user, crew) do
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

  def handle_info({ItsmWeb.CrewLive.FormComponent, {:saved, crew}}, socket) do
    {:noreply, stream_insert(socket, :crews, crew)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, event, %Crew{} = item, socket)
       when event in [:update_crew, :add_users, :switch_leader] do
    %{current_user: user} = socket.assigns

    if(Enum.any?(item.users, &(&1.id == user.id)) || user.id == item.leader.id) do
      opts = [
        resource_name: get_resource_name(event),
        stream_name: :crews
      ]

      {:noreply,
       socket
       |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
       |> stream_insert(:crews, item)}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(action_user, :delete_crew = event, %Crew{} = item, socket) do
    opts = [
      resource_name: gettext("Crew"),
      stream_name: :crews
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(
         action_user,
         :delete_user = event,
         {%Crew{} = item, %User{} = deleted_user},
         socket
       ) do
    %{current_user: user} = socket.assigns

    if(user.id == deleted_user.id) do
      opts = [
        resource_name: gettext("Member"),
        stream_name: :crews
      ]

      {:noreply, ItsmWeb.LiveUtils.handle_standard_pubsub(socket, action_user, event, item, opts)}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(_action_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp get_resource_name(:update_crew), do: gettext("Crew")
  defp get_resource_name(:add_users), do: gettext("Members")
  defp get_resource_name(:switch_leader), do: gettext("Crew Leader")
end
