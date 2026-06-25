defmodule ItsmWeb.BoardLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Boards
  alias Itsm.Boards.Board
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:boards, []) |> Itsm.PubSub.Helper.subscribe(Boards)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
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

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:boards, Board, params, url)
    |> assign(:page_title, "Listing Boards")
    |> assign(:board, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Board")
    |> assign(:board, %Board{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Board")
    |> assign(:board, Boards.get_board!(id))
  end

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
