defmodule ItsmWeb.AdminCommonCodeLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes
  alias Itsm.Common.CommonCode

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :common_codes, CommonCodes.list_common_codes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit  Common Code")
    |> assign(:common_code, CommonCodes.get_common_code!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Common Code")
    |> assign(:common_code, %CommonCode{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Common codes")
    |> assign(:common_code, nil)
  end

  @impl true
  def handle_info({ItsmWeb.AdminCommonCodeLive.FormComponent, {:saved, common_code}}, socket) do
    {:noreply, stream_insert(socket, :common_codes, common_code)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    common_code = CommonCodes.get_common_code!(id)
    {:ok, _} = CommonCodes.delete_common_code(common_code)

    {:noreply, stream_delete(socket, :common_codes, common_code)}
  end
end
