defmodule ItsmWeb.EvaluationLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Evaluations

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:evaluation, Evaluations.get_evaluation!(id))
     |> Itsm.PubSub.Helper.subscribe(Evaluations, id: id)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp page_title(:show), do: "Show Evaluation"
  defp page_title(:edit), do: "Edit Evaluation"

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{evaluation: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :evaluation, resource_name: gettext("Evaluation")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_evaluation),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []
end
