defmodule ItsmWeb.Admin.CrewLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews
  alias Itsm.Crews.Crew
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Crews)

    {:ok, stream(socket, :crews, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = crew_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, crew} = Crews.delete_crew(action_user, crew_params)

    {:noreply, stream_delete(socket, :crews, crew)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [default_columns: [:name, :description, {:users, :display_name}]]

    value = Paging.search_and_pagination(Crew, params, url, opts)

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

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :crew,
      resource_name: gettext("Crew"),
      stream_name: :crews,
      push_patch: [to: ~p"/admin/crews?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
