defmodule ItsmWeb.Admin.CrewLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews
  alias Itsm.Crews.Crew

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Crew, id)
      Itsm.Utils.subscribes(Crew)
    end

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:crew, Crews.get_crew!(id))}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Crew"
  defp page_title(:edit), do: "Edit Crew"

  defp handle_pubsub(
         user,
         event,
         %{id: id} = item,
         %{assigns: %{crew: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :crew, resource_name: gettext("Crew")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_crew),
    do: [push_navigate: [to: ~p"/admin/crews"]]

  defp push_event_action(_), do: []
end
