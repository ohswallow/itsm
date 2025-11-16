defmodule Itsm.EvaluationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Evaluations` context.
  """

  @doc """
  Generate a evaluation.
  """
  def evaluation_fixture(attrs \\ %{}) do
    {:ok, evaluation} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        rating: 120.5
      })
      |> Itsm.Evaluations.create_evaluation()

    evaluation
  end
end
