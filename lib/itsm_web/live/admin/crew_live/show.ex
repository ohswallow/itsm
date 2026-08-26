defmodule ItsmWeb.Admin.CrewLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, gettext("Show Crew"))
     |> assign(:crew, Crews.get_crew!(id))
     |> assign(:avg_rating, Itsm.Admin.Evaluations.average_rating_by_crew(id))
     |> Itsm.PubSub.Helper.subscribe(Crews, id: id, is_admin: true)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{crew: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :crew, resource_name: gettext("Crew")]
      |> push_event_action(event)

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(opts, :delete_crew),
    do: Keyword.put(opts, :push_navigate, to: ~p"/admin/crews")

  defp push_event_action(opts, _), do: opts
end
