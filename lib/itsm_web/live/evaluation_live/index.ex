defmodule ItsmWeb.EvaluationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Evaluations
  alias Itsm.Evaluations.Evaluation

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Evaluation)

    {:ok, stream(socket, :evaluations, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = evaluation_params, socket) do
    {:ok, evaluation} = Evaluations.delete_evaluation(evaluation_params)

    {:noreply, stream_delete(socket, :evaluations, evaluation)}
  end

  @impl true
  def handle_info({ItsmWeb.EvaluationLive.FormComponent, {:saved, evaluation}}, socket) do
    {:noreply, stream_insert(socket, :evaluations, evaluation)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Evaluation")
    |> assign(:evaluation, Evaluations.get_evaluation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Evaluation")
    |> assign(:evaluation, %Evaluation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Evaluations")
    |> stream(:evaluation, Evaluations.list_evaluations(), reset: true)
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :evaluation,
      resource_name: gettext("Evaluation"),
      stream_name: :evaluations,
      push_patch: [to: ~p"/evaluations"]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
