defmodule ItsmWeb.Admin.RequestLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:request, Requests.get_request!(id))}
  end

  defp page_title(:show), do: "Show Request"
  defp page_title(:edit), do: "Edit Request"
end
