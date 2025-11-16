defmodule ItsmWeb.CommentLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.CommentsFixtures

  @create_attrs %{comment: "some comment"}
  @update_attrs %{comment: "some updated comment"}
  @invalid_attrs %{comment: nil}

  defp create_comment(_) do
    comment = comment_fixture()
    %{comment: comment}
  end

  describe "Index" do
    setup [:create_comment]

    test "lists all comments", %{conn: conn, comment: comment} do
      {:ok, _index_live, html} = live(conn, ~p"/comments")

      assert html =~ "Listing Comments"
      assert html =~ comment.comment
    end

    test "saves new comment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert index_live |> element("a", "New Comment") |> render_click() =~
               "New Comment"

      assert_patch(index_live, ~p"/comments/new")

      assert index_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#comment-form", comment: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/comments")

      html = render(index_live)
      assert html =~ "Comment created successfully"
      assert html =~ "some comment"
    end

    test "updates comment in listing", %{conn: conn, comment: comment} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert index_live |> element("#comments-#{comment.id} a", "Edit") |> render_click() =~
               "Edit Comment"

      assert_patch(index_live, ~p"/comments/#{comment}/edit")

      assert index_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#comment-form", comment: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/comments")

      html = render(index_live)
      assert html =~ "Comment updated successfully"
      assert html =~ "some updated comment"
    end

    test "deletes comment in listing", %{conn: conn, comment: comment} do
      {:ok, index_live, _html} = live(conn, ~p"/comments")

      assert index_live |> element("#comments-#{comment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#comments-#{comment.id}")
    end
  end

  describe "Show" do
    setup [:create_comment]

    test "displays comment", %{conn: conn, comment: comment} do
      {:ok, _show_live, html} = live(conn, ~p"/comments/#{comment}")

      assert html =~ "Show Comment"
      assert html =~ comment.comment
    end

    test "updates comment within modal", %{conn: conn, comment: comment} do
      {:ok, show_live, _html} = live(conn, ~p"/comments/#{comment}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Comment"

      assert_patch(show_live, ~p"/comments/#{comment}/show/edit")

      assert show_live
             |> form("#comment-form", comment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#comment-form", comment: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/comments/#{comment}")

      html = render(show_live)
      assert html =~ "Comment updated successfully"
      assert html =~ "some updated comment"
    end
  end
end
