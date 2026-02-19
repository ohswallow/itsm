defmodule ItsmWeb.AdminCommonCodeLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:common_code, CommonCodes.get_common_code!(id))}
  end

  defp page_title(:show), do: "Show Common Code"
  defp page_title(:edit), do: "Edit Common Code"
end
