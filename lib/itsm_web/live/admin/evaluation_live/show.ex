defmodule ItsmWeb.Admin.EvaluationLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Evaluations

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Show Evaluation")
     |> assign(:evaluation, Evaluations.get_evaluation!(id) |> Itsm.Repo.preload(:crew))
     |> Itsm.PubSub.Helper.subscribe(Itsm.Admin.Evaluations, id: id, is_admin: true)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{evaluation: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :evaluation, resource_name: gettext("Evaluation")]
      |> push_event_action(event)

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(opts, :delete_evaluation),
    do: Keyword.put(opts, :push_navigate, to: ~p"/admin/evaluations")

  defp push_event_action(opts, _), do: opts
end
