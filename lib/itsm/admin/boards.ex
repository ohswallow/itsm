defmodule Itsm.Admin.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Boards.Board

  defdelegate get_board!(id), to: Itsm.Boards

  def get_board_by_slug(slug), do: Repo.get_by!(Board, slug: slug)

  defdelegate list_boards, to: Itsm.Boards

  defdelegate create_board(attrs \\ %{}), to: Itsm.Boards

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
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

  defdelegate delete_board(attrs), to: Itsm.Boards

  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def get_select_options() do
    Board |> select([b], {b.name, b.id}) |> Repo.all()
  end
end
