defmodule ItsmWeb.DelegationLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Delegations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:delegation, Delegations.get_delegation!(id))}
  end
end
