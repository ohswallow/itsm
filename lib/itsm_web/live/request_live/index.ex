defmodule ItsmWeb.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Service
  alias Itsm.Paging
  alias ItsmWeb.LiveUtils

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:requests, [])
     |> Itsm.PubSub.Helper.subscribe(Requests)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, url, params)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    %{current_user: user} = socket.assigns

    case Service.delete_request(user, id) do
      {:ok, request} ->
        {:noreply, stream_delete(socket, :requests, request)}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, LiveUtils.translate_error(step, :request))}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :index, url, params) do
    socket
    |> assign_paged_stream(:requests, Request, params, url)
    |> assign(:page_title, "Listing Requests")
  end

  defp apply_action(socket, :edit, _url, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Requests")
    |> assign(:request, Requests.get_request!(id))
  end

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    %{current_user: %{organization_code: organization_code}} = socket.assigns

    opts = [
      default_columns: [:title, :description, :env, :requestor_name],
      preloads: [:category, :requestor, :assignee_crew]
    ]

    %{entries: entries, results: results} =
      schema
      |> Paging.filter_status([requestor: :organization_code], ["CM", "FG", organization_code],
        query_cond: :in
      )
      |> Paging.search_and_pagination(params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Request"),
      target_key: :requests,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
