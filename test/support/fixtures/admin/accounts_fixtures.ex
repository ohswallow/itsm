defmodule Itsm.Admin.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Admin.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        confirmed_at: ~U[2026-04-19 07:59:00Z],
        current_password: "some current_password",
        department: "some department",
        department_code: "some department_code",
        display_name: "some display_name",
        email: "some email",
        employee_number: "some employee_number",
        hashed_password: "some hashed_password",
        organization: "some organization",
        organization_code: "some organization_code",
        password: "some password",
        role: "some role"
      })
      |> Itsm.Admin.Accounts.create_user()

    user
  end
end
