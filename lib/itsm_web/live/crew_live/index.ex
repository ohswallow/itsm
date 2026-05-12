defmodule ItsmWeb.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Accounts.User
  alias ItsmWeb.LiveUtils
  alias Itsm.Utils

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents

  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    if connected?(socket), do: Utils.subscribes(Crews)

    {:ok, stream(socket, :crews, Crews.list_my_crews(user))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # 1. 목록 조회 (:index)
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Crews")
    |> assign(:crew, nil)
  end

  # 2. 생성 모달 (:new)
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  # 3. 수정 모달 (:edit)
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

  defp handle_pubsub(action_user, event, {:crews, %Crew{} = crew}, socket)
       when event in [:update_crew, :add_users, :switch_leader] do
    %{current_user: user} = socket.assigns
    crew = Crews.with_assoc(crew, [:leader, :users])

    if(Enum.any?(crew.users, &(&1.id == user.id)) || user == crew.leader) do
      {:noreply,
       stream_insert(socket, :crews, crew)
       |> put_flash(
         :info,
         gettext("%{crew_name} added/updated by %{action_user}.",
           crew_name: crew.name,
           action_user: action_user.display_name
         )
       )}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(action_user, :delete_crew, {:crews, %Crew{} = crew}, socket) do
    {:noreply,
     stream_delete(socket, :crews, crew)
     |> put_flash(
       :info,
       gettext("%{crew_name} deleted by %{action_user}.",
         crew_name: crew.name,
         action_user: action_user.display_name
       )
     )}
  end

  defp handle_pubsub(
         action_user,
         :delete_user,
         {:crews, %Crew{} = crew, %User{} = deleted_user},
         socket
       ) do
    %{current_user: user} = socket.assigns

    if(user == deleted_user) do
      {:noreply,
       stream_delete(socket, :crews, crew)
       |> put_flash(
         :info,
         gettext("You have been removed from the crew by %{action_user}.",
           action_user: action_user.display_name
         )
       )}
    else
      {:noreply, socket}
    end
  end

  defp handle_pubsub(_action_user, _event, _item, socket) do
    {:noreply, socket}
  end
end
