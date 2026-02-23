defmodule Itsm.CommonFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Common` context.
  """

  @doc """
  Generate a common code.
  """
  def common_code_fixture(attrs \\ %{}) do
    {:ok, codes} =
      attrs
      |> Enum.into(%{
        code: "some code",
        description: "some description",
        group_code: "some group_code",
        is_active: true,
        label: "some label",
        sort_order: 42
      })
      |> Itsm.Admin.CommonCodes.create_common_code()

  #   codes
  # end
end
