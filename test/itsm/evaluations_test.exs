defmodule Itsm.EvaluationsTest do
  use Itsm.DataCase

  alias Itsm.Evaluations

  describe "evaluations" do
    alias Itsm.Evaluations.Evaluation

    import Itsm.EvaluationsFixtures

    @invalid_attrs %{comment: nil, rating: nil}

    test "list_evaluations/0 returns all evaluations" do
      evaluation = evaluation_fixture()
      assert Evaluations.list_evaluations() == [evaluation]
    end

    test "get_evaluation!/1 returns the evaluation with given id" do
      evaluation = evaluation_fixture()
      assert Evaluations.get_evaluation!(evaluation.id) == evaluation
    end

    test "create_evaluation/1 with valid data creates a evaluation" do
      valid_attrs = %{comment: "some comment", rating: 120.5}

      assert {:ok, %Evaluation{} = evaluation} = Evaluations.create_evaluation(valid_attrs)
      assert evaluation.comment == "some comment"
      assert evaluation.rating == 120.5
    end

    test "create_evaluation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Evaluations.create_evaluation(@invalid_attrs)
    end

    test "update_evaluation/2 with valid data updates the evaluation" do
      evaluation = evaluation_fixture()
      update_attrs = %{comment: "some updated comment", rating: 456.7}

      assert {:ok, %Evaluation{} = evaluation} = Evaluations.update_evaluation(evaluation, update_attrs)
      assert evaluation.comment == "some updated comment"
      assert evaluation.rating == 456.7
    end

    test "update_evaluation/2 with invalid data returns error changeset" do
      evaluation = evaluation_fixture()
      assert {:error, %Ecto.Changeset{}} = Evaluations.update_evaluation(evaluation, @invalid_attrs)
      assert evaluation == Evaluations.get_evaluation!(evaluation.id)
    end

    test "delete_evaluation/1 deletes the evaluation" do
      evaluation = evaluation_fixture()
      assert {:ok, %Evaluation{}} = Evaluations.delete_evaluation(evaluation)
      assert_raise Ecto.NoResultsError, fn -> Evaluations.get_evaluation!(evaluation.id) end
    end

    test "change_evaluation/1 returns a evaluation changeset" do
      evaluation = evaluation_fixture()
      assert %Ecto.Changeset{} = Evaluations.change_evaluation(evaluation)
    end
  end
end
