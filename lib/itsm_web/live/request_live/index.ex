defmodule ItsmWeb.RequestLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Requests

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Requests")
     |> stream(:requests, Requests.list_requests())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Requests
      <%!-- <:actions>
        <.button phx-click={JS.dispatch("click", to: {:inner, "a"})}>
          <.link navigate={~p"/requests/new"}>New Request</.link>
        </.button>
      </:actions> --%>
    </.header>

    <.table
      id="requests"
      rows={@streams.requests}
      row_click={
        fn {_id, request} -> JS.navigate("/#{request.category.request_name}/#{request.id}") end
      }
    >
      <:col :let={{_id, request}} label={gettext("Title")}>{request.title}</:col>

      <:col
        :let={{_id, request}}
        label={gettext("Description")}
      >
        <div class="w-[90px] truncate">{request.description}</div>
      </:col>

      <:col :let={{_id, request}} label={gettext("Environment")}>{request.env}</:col>

      <:col :let={{id, request}} label={gettext("Due Date")}>
        <div id={id} phx-hook="LocalTime.ToLocale" utc-value={request.due_date} />
      </:col>

      <:col :let={{_id, request}} label={gettext("Request Type")}>
        {request.category.request_name}
      </:col>

      <:col :let={{_id, request}} label={gettext("Request Name")}>{request.category.name}</:col>

      <%!-- <:col :let={{_id, request}} label="Create vm common k">{request.common_k_create_vms}</:col> --%>
      <:action :let={{_id, request}}>
        <div class="sr-only"><.link navigate={~p"/requests/#{request}"}>Show</.link></div>
        <.link navigate={"/#{request.category.request_name}/#{request.id}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, request}}>
        <.link
          phx-click={JS.push("delete", value: %{id: request.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Requests.get_request!(id)
    {:ok, _} = Requests.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end
end
