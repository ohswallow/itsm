defmodule ItsmWeb.RequestLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Requests

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Request {@request.id}
      <:subtitle>This is a request record from your database.</:subtitle>
      
      <:actions>
        <.button phx-click={JS.dispatch("click", to: {:inner, "a"})}>
          <.link navigate={~p"/requests/#{@request}/edit?return_to=show"}>Edit request</.link>
        </.button>
      </:actions>
    </.header>

    <.list>
      <:item title="Title">{@request.title}</:item>
      
      <:item title="Description">{@request.description}</:item>
      
      <:item title="Env">{@request.env}</:item>
      
      <:item title="Due date">{@request.due_date}</:item>
      
      <:item title="Create vm common k">{@request.common_k_create_vms}</:item>
    </.list>

    <.back navigate={~p"/requests"}>Back to requests</.back>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Request")
     |> assign(:request, Requests.get_request!(id))}
  end
end
