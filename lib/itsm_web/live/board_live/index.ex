defmodule ItsmWeb.BoardLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Boards
  alias Itsm.Boards.Board
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Boards)

    {:ok, stream(socket, :boards, [])}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = board_params, socket) do
    {:ok, board} = Boards.delete_board(board_params)

    {:noreply, stream_delete(socket, :boards, board)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, Board, [:name, :slug, :description, :metadata])

    socket
    |> assign(:results, value.results)
    |> stream(:boards, value.entries, reset: true)
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

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :board,
      resource_name: gettext("Board"),
      stream_name: :boards,
      push_patch: [to: ~p"/boards?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
