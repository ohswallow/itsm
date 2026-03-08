defmodule ItsmWeb.Admin.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :crews, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    crew = Crews.get_crew!(id)
    {:ok, _} = Crews.delete_crew(crew)

    {:noreply, stream_delete(socket, :crews, crew)}
  end

  @impl true
  def handle_info({ItsmWeb.Admin.CrewLive.FormComponent, {:saved, crew}}, socket) do
    {:noreply, stream_insert(socket, :crews, crew)}
  end

  defp apply_action(socket, :index, params, url) do
    results =
      Paging.search_and_pagination(params, url, Crew, [
        :name,
        :description,
        {:users, :display_name}
      ])

    socket
    |> assign(:results, results)
    |> stream(:crews, results.entries, reset: true)
    |> assign(:page_title, "Listing Crews")
    |> assign(:crew, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Crew")
    |> assign(:crew, Crews.get_crew!(id))
  end
end
