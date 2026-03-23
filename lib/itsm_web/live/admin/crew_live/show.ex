defmodule ItsmWeb.Admin.CrewLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(:crew, id)
      Itsm.Utils.subscribes(:crews)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:crew, Crews.get_crew!(id))}
  end

  @impl true
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Crew"
  defp page_title(:edit), do: "Edit Crew"

  defp handle_pubsub(:update_crew, %{id: id} = crew, %{assigns: %{crew: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> assign(:crew, crew)
     |> put_flash(:info, gettext("Updated") <> " " <> gettext("Crew"))
     |> push_patch(to: ~p"/admin/crews/#{crew}")}
  end

  defp handle_pubsub(:delete_crew, %{id: id}, %{assigns: %{crew: %{id: id}}} = socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Crew"))
     |> push_navigate(to: ~p"/admin/crews")}
  end

  defp handle_pubsub(_event, _item, socket) do
    {:noreply, socket}
  end
end
