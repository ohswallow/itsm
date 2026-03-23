defmodule ItsmWeb.Admin.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribes(:crews)
    end

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
  def handle_info({:pubsub, {event, item}}, socket) do
    handle_pubsub(event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, Crew, [
        :name,
        :description,
        {:users, :display_name}
      ])

    socket
    |> assign(:results, value.results)
    |> stream(:crews, value.entries, reset: true)
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

  defp handle_pubsub(event, _crew, socket)
       when event in [:create_crew, :update_crew] do
    {:noreply,
     socket
     |> put_flash(
       :info,
       if(event == :create_crew,
         do: gettext("Created") <> " " <> gettext("Crew"),
         else: gettext("Updated") <> " " <> gettext("Crew")
       )
     )
     |> push_patch(to: ~p"/admin/crews?#{socket.assigns[:results][:params] || %{}}")}
  end

  defp handle_pubsub(:delete_crew, crew, socket) do
    {:noreply,
     socket
     |> put_flash(:info, gettext("Deleted") <> " " <> gettext("Crew"))
     |> stream_delete(:crews, crew)}
  end
end
