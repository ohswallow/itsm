defmodule ItsmWeb.DelegationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Delegations
  alias Itsm.Delegations.Delegation

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :delegations, Delegations.list_delegations())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Delegation")
    |> assign(:delegation, Delegations.get_delegation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Delegation")
    |> assign(:delegation, %Delegation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Delegations")
    |> assign(:delegation, nil)
  end

  @impl true
  def handle_info({ItsmWeb.DelegationLive.FormComponent, {:saved, delegation}}, socket) do
    {:noreply, stream_insert(socket, :delegations, delegation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    delegation = Delegations.get_delegation!(id)
    {:ok, _} = Delegations.delete_delegation(delegation)

    {:noreply, stream_delete(socket, :delegations, delegation)}
  end
end
