defmodule ItsmWeb.Admin.EvaluationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Evaluations
  alias Itsm.Evaluations.Evaluation
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:evaluations, [])
     |> Itsm.PubSub.Helper.subscribe(Evaluations, is_admin: true)
     |> stream(:crew_ratings, Evaluations.list_average_rating())}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:evaluations, Evaluation, params, url)
     |> assign(:page_title, "Listing Evaluations")}
  end

  def handle_event("delete", %{"id" => _id} = evaluation_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, evaluation} = Evaluations.delete_evaluation(action_user, evaluation_params)

    {:noreply, stream_delete(socket, :evaluations, evaluation)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:comment, :rating, crew: :name], preloads: [crew: :name]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Evaluation"),
      target_key: :evaluations,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
