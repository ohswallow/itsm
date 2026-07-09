defmodule ItsmWeb.Admin.BoardLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Boards
  alias Itsm.Boards.Board
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:boards, []) |> Itsm.PubSub.Helper.subscribe(Boards, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:boards, Board, params, url)
     |> assign(:page_title, gettext("Listing Boards"))}
  end

  def handle_event("delete", %{"id" => _id} = board_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, board} = Boards.delete_board(action_user, board_params)

    {:noreply, stream_delete(socket, :boards, board)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:name, :slug, :description, :metadata]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Board"),
      target_key: :boards,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
