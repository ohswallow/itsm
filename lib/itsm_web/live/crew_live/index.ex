defmodule ItsmWeb.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Accounts.User
  alias ItsmWeb.LiveUtils

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents

  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    if connected?(socket) do
      Crews.subscribe_crews()
    end

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
    crew = Crews.get_crew!(id)
    current_user = socket.assigns.current_user

    case Crews.delete_crew(crew, current_user) do
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

  def handle_info({:crews, {event, %Crew{} = crew}}, socket)
      when event in [:create_crew, :update_crew, :add_users, :leader_changed] do
    %{current_user: user} = socket.assigns
    crew = Crews.with_assoc(crew, [:leader, :users])

    if(Enum.member?(crew.users, user) || user == crew.leader) do
      {:noreply, stream_insert(socket, :crews, crew)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:crews, {:delete_crew, %Crew{} = crew}}, socket) do
    {:noreply, stream_delete(socket, :crews, crew)}
  end

  def handle_info({:crews, {:delete_user, %Crew{} = crew, %User{} = deleted_user}}, socket) do
    %{current_user: user} = socket.assigns

    if(user == deleted_user) do
      {:noreply, stream_delete(socket, :crews, crew)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_event, socket), do: {:noreply, socket}
end
