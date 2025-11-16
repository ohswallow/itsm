defmodule ItsmWeb.EvaluationLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.EvaluationsFixtures

  @create_attrs %{comment: "some comment", rating: 120.5}
  @update_attrs %{comment: "some updated comment", rating: 456.7}
  @invalid_attrs %{comment: nil, rating: nil}

  defp create_evaluation(_) do
    evaluation = evaluation_fixture()
    %{evaluation: evaluation}
  end

  describe "Index" do
    setup [:create_evaluation]

    test "lists all evaluations", %{conn: conn, evaluation: evaluation} do
      {:ok, _index_live, html} = live(conn, ~p"/evaluations")

      assert html =~ "Listing Evaluations"
      assert html =~ evaluation.comment
    end

    test "saves new evaluation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/evaluations")

      assert index_live |> element("a", "New Evaluation") |> render_click() =~
               "New Evaluation"

      assert_patch(index_live, ~p"/evaluations/new")

      assert index_live
             |> form("#evaluation-form", evaluation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#evaluation-form", evaluation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/evaluations")

      html = render(index_live)
      assert html =~ "Evaluation created successfully"
      assert html =~ "some comment"
    end

    test "updates evaluation in listing", %{conn: conn, evaluation: evaluation} do
      {:ok, index_live, _html} = live(conn, ~p"/evaluations")

      assert index_live |> element("#evaluations-#{evaluation.id} a", "Edit") |> render_click() =~
               "Edit Evaluation"

      assert_patch(index_live, ~p"/evaluations/#{evaluation}/edit")

      assert index_live
             |> form("#evaluation-form", evaluation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#evaluation-form", evaluation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/evaluations")

      html = render(index_live)
      assert html =~ "Evaluation updated successfully"
      assert html =~ "some updated comment"
    end

    test "deletes evaluation in listing", %{conn: conn, evaluation: evaluation} do
      {:ok, index_live, _html} = live(conn, ~p"/evaluations")

      assert index_live |> element("#evaluations-#{evaluation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#evaluations-#{evaluation.id}")
    end
  end

  describe "Show" do
    setup [:create_evaluation]

    test "displays evaluation", %{conn: conn, evaluation: evaluation} do
      {:ok, _show_live, html} = live(conn, ~p"/evaluations/#{evaluation}")

      assert html =~ "Show Evaluation"
      assert html =~ evaluation.comment
    end

    test "updates evaluation within modal", %{conn: conn, evaluation: evaluation} do
      {:ok, show_live, _html} = live(conn, ~p"/evaluations/#{evaluation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Evaluation"

      assert_patch(show_live, ~p"/evaluations/#{evaluation}/show/edit")

      assert show_live
             |> form("#evaluation-form", evaluation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#evaluation-form", evaluation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/evaluations/#{evaluation}")

      html = render(show_live)
      assert html =~ "Evaluation updated successfully"
      assert html =~ "some updated comment"
    end
  end
end
