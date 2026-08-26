defmodule Itsm.Admin.Evaluations do
  @moduledoc """
  The Evaluations context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Evaluations.Evaluation

  def get_evaluation!(id), do: Repo.get!(Evaluation, id)

  def average_rating_by_crew(crew_id) when is_binary(crew_id) do
    Evaluation
    |> from()
    |> where([e], e.crew_id == ^crew_id)
    |> select([e], avg(e.rating))
    |> Repo.one()
    |> case do
      nil -> 0.0
      val -> val
    end
  end

  def list_evaluations, do: Repo.all(Evaluation)

  def list_average_rating do
    Evaluation
    |> from()
    |> join(:inner, [e], c in assoc(e, :crew))
    |> group_by([e, c], [e.crew_id, c.name])
    |> select([e, c], %{id: e.crew_id, crew_id: e.crew_id, avg_rating: avg(e.rating)})
    |> select_merge([_e, c], %{crew_name: c.name})
    |> Repo.all()
  end

  def create_evaluation(%User{} = action_user, attrs) do
    %Evaluation{}
    |> Evaluation.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, evaluation} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_evaluation, evaluation})
        {:ok, evaluation}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_evaluation(%User{} = action_user, %Evaluation{} = evaluation, attrs) do
    evaluation
    |> Evaluation.admin_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, evaluation} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_evaluation, evaluation},
          id: evaluation.id
        )

        {:ok, evaluation}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_evaluation(%User{} = action_user, %{"id" => id}) do
    get_evaluation!(id)
    |> Repo.delete()
    |> case do
      {:ok, evaluation} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_evaluation, evaluation},
          id: evaluation.id
        )

        {:ok, evaluation}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_evaluation(%Evaluation{} = evaluation, attrs \\ %{}) do
    Evaluation.admin_changeset(evaluation, attrs)
  end
end
