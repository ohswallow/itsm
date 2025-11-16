defmodule Itsm.Evaluations do
  @moduledoc """
  The Evaluations context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Evaluations.Evaluation

  @doc """
  Returns the list of evaluations.

  ## Examples

      iex> list_evaluations()
      [%Evaluation{}, ...]

  """
  def list_evaluations do
    Repo.all(Evaluation)
  end

  @doc """
  Gets a single evaluation.

  Raises `Ecto.NoResultsError` if the Evaluation does not exist.

  ## Examples

      iex> get_evaluation!(123)
      %Evaluation{}

      iex> get_evaluation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_evaluation!(id), do: Repo.get!(Evaluation, id)

  @doc """
  Creates a evaluation.

  ## Examples

      iex> create_evaluation(%{field: value})
      {:ok, %Evaluation{}}

      iex> create_evaluation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_evaluation(attrs \\ %{}) do
    %Evaluation{}
    |> Evaluation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a evaluation.

  ## Examples

      iex> update_evaluation(evaluation, %{field: new_value})
      {:ok, %Evaluation{}}

      iex> update_evaluation(evaluation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_evaluation(%Evaluation{} = evaluation, attrs) do
    evaluation
    |> Evaluation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a evaluation.

  ## Examples

      iex> delete_evaluation(evaluation)
      {:ok, %Evaluation{}}

      iex> delete_evaluation(evaluation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_evaluation(%Evaluation{} = evaluation) do
    Repo.delete(evaluation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking evaluation changes.

  ## Examples

      iex> change_evaluation(evaluation)
      %Ecto.Changeset{data: %Evaluation{}}

  """
  def change_evaluation(%Evaluation{} = evaluation, attrs \\ %{}) do
    Evaluation.changeset(evaluation, attrs)
  end
end
