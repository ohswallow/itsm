defmodule ItsmWeb.Admin.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests
  alias Itsm.Paging
  alias Itsm.Service.Request

  def mount(_params, _session, socket) do
    {:ok,
     socket |> stream(:requests, []) |> Itsm.PubSub.Helper.subscribe(Requests, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = request_params, socket) do
    %{current_user: action_user} = socket.assigns

    case Requests.delete_request(action_user, request_params) do
      {:ok, request} ->
        {:noreply, stream_delete(socket, :requests, request)}

      {:error, :foreign_approvals, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [
      default_columns: [:id, :title, :description, :env, :requestor_name],
      preloads: [requestor: :organization_code, category: [:request_name, :name, :affiliate]]
    ]

    value =
      Paging.search_and_pagination(Request, params, url, opts)

    socket
    |> assign(:results, value.results)
    |> stream(:requests, value.entries, reset: true)
    |> assign(:page_title, "Listing Requests")
    |> assign(:request, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, %Request{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, Requests.get_request!(id))
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Request"),
      target_key: :requests,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
