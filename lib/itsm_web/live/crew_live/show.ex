defmodule ItsmWeb.CrewLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Team

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:crew, Team.get_crew!(id))}
  end

  defp page_title(:show), do: "Show Crew"
  defp page_title(:edit), do: "Edit Crew"
end
