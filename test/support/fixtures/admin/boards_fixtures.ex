defmodule Itsm.Admin.BoardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Admin.Boards` context.
  """

  @doc """
  Generate a board.
  """
  def board_fixture(attrs \\ %{}) do
    {:ok, board} =
      attrs
      |> Enum.into(%{
        description: "some description",
        metadata: %{},
        name: "some name",
        slug: "some slug"
      })
      |> Itsm.Admin.Boards.create_board()

    board
  end
end
