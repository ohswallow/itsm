defmodule ItsmWeb.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Team
  alias Itsm.Team.Crew

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :crews, Team.list_crews())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Crew")
    |> assign(:crew, Team.get_crew!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Crews")
    |> assign(:crew, nil)
  end

  @impl true
  def handle_info({ItsmWeb.CrewLive.FormComponent, {:saved, crew}}, socket) do
    {:noreply, stream_insert(socket, :crews, crew)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    crew = Team.get_crew!(id)
    {:ok, _} = Team.delete_crew(crew)

    {:noreply, stream_delete(socket, :crews, crew)}
  end
end
