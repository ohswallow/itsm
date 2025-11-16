defmodule Itsm.TeamFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Team` context.
  """

  @doc """
  Generate a unique crew name.
  """
  def unique_crew_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a crew.
  """
  def crew_fixture(attrs \\ %{}) do
    {:ok, crew} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: unique_crew_name()
      })
      |> Itsm.Team.create_crew()

    crew
  end

  @doc """
  Generate a member.
  """
  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> Enum.into(%{

      })
      |> Itsm.Team.create_member()

    member
  end
end
