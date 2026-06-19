defmodule Itsm.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Boards.Board

  def get_board!(id), do: Repo.get!(Board, id)
  def get_board(id), do: Repo.get(Board, id)

  def list_boards, do: Repo.all(Board)

  def create_board(%User{} = action_user, attrs) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, board} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_board, board})
        {:ok, board}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_board(%User{} = action_user, %Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, board} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_board, board},
          id: board.id
        )

        {:ok, board}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_board(%User{} = action_user, %{"id" => id}) do
    get_board!(id)
    |> Repo.delete()
    |> case do
      {:ok, board} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_board, board},
          id: board.id
        )

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
