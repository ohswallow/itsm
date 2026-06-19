defmodule Itsm.CommonFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Common` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a common code.
  """
  def common_code_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        code: "some code",
        description: "some description",
        group_code: "some group_code",
        is_active: true,
        label: "some label",
        sort_order: 42
      })

    {:ok, codes} = Itsm.Admin.CommonCodes.create_common_code(%User{}, attrs)

    codes
  end
end
