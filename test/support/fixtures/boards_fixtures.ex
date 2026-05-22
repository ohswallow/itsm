defmodule Itsm.BoardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Boards` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a board.
  """
  def board_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        description: "some description",
        metadata: %{},
        name: "some name",
        slug: "some slug"
      })

    {:ok, board} = Itsm.Boards.create_board(%User{}, attrs)

    board
  end
end
