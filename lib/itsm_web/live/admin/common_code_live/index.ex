defmodule ItsmWeb.Admin.CommonCodeLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes
  alias Itsm.Common.CommonCode
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :common_codes, [])}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    common_code = CommonCodes.get_common_code!(id)
    {:ok, _} = CommonCodes.delete_common_code(common_code)

    {:noreply, stream_delete(socket, :common_codes, common_code)}
  end

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, CommonCode, [:group_code, :label, :code])

    socket
    |> assign(:results, value.results)
    |> stream(:common_codes, value.entries, reset: true)
    |> assign(:page_title, "Listing Common codes")
    |> assign(:common_code, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Common Code")
    |> assign(:common_code, %CommonCode{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit  Common Code")
    |> assign(:common_code, CommonCodes.get_common_code!(id))
  end
end
