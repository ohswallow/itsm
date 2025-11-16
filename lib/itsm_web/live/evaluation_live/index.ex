defmodule ItsmWeb.EvaluationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Evaluations
  alias Itsm.Evaluations.Evaluation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :evaluations, Evaluations.list_evaluations())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
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
    |> assign(:evaluation, nil)
  end

  @impl true
  def handle_info({ItsmWeb.EvaluationLive.FormComponent, {:saved, evaluation}}, socket) do
    {:noreply, stream_insert(socket, :evaluations, evaluation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    evaluation = Evaluations.get_evaluation!(id)
    {:ok, _} = Evaluations.delete_evaluation(evaluation)

    {:noreply, stream_delete(socket, :evaluations, evaluation)}
  end
end
