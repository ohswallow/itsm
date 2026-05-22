defmodule Itsm.EvaluationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Evaluations` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a evaluation.
  """
  def evaluation_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        rating: 120.5
      })

    {:ok, evaluation} = Itsm.Evaluations.create_evaluation(%User{}, attrs)

    evaluation
  end
end
