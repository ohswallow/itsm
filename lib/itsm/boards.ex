defmodule Itsm.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Boards.Board

  def get_board!(id), do: Repo.get!(Board, id)
  def get_board(id), do: Repo.get(Board, id)

  def list_boards, do: Repo.all(Board)

  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, board} ->
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :create_board, board})
        {:ok, board}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, board} ->
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :update_board, board})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :update_board, board})
        {:ok, board}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_board(%{"id" => id} = attrs) do
    Repo.delete(get_board!(id))
    |> case do
      {:ok, board} ->
        Itsm.Utils.broadcast(Board, {attrs["current_user"], :delete_board, board})
        Itsm.Utils.broadcasts(Board, {attrs["current_user"], :delete_board, board})
        {:ok, board}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end

  def get_select_options() do
    Board |> select([b], {b.name, b.id}) |> Repo.all()
  end
end
