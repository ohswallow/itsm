defmodule ItsmWeb.Admin.BoardLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Boards
  alias Itsm.Boards.Board

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"board" => board_params}, socket) do
    changeset = Boards.change_board(%Board{}, board_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"board" => board_params}, socket) do
    save_board(socket, socket.assigns.live_action, board_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Board")
    |> assign(:board, %Board{})
    |> assign_new(:form, fn -> to_form(Boards.change_board(%Board{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    board = Boards.get_board!(id)

    socket
    |> assign(:page_title, "Edit Board")
    |> assign(:board, board)
    |> assign_new(:form, fn -> to_form(Boards.change_board(board)) end)
    |> Itsm.PubSub.Helper.subscribe(Boards, id: id, is_admin: true)
  end

  defp save_board(socket, :edit, board_params) do
    %{current_scope: %{user: action_user}, board: board} = socket.assigns

    case Boards.update_board(action_user, board, board_params) do
      {:ok, _board} ->
        {:noreply, socket |> push_navigate(to: "/admin/boards")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_board(socket, :new, board_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Boards.create_board(action_user, board_params) do
      {:ok, _board} ->
        {:noreply, socket |> push_navigate(to: "/admin/boards")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_board,
         %{id: id},
         %{assigns: %{board: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_board,
         %{id: id},
         %{assigns: %{board: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: "/admin/boards")}
  end
end
