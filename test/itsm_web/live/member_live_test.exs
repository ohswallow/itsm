defmodule ItsmWeb.MemberLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.TeamFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_member(_) do
    member = member_fixture()
    %{member: member}
  end

  describe "Index" do
    setup [:create_member]

    test "lists all members", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/members")

      assert html =~ "Listing Members"
    end

    test "saves new member", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/members")

      assert index_live |> element("a", "New Member") |> render_click() =~
               "New Member"

      assert_patch(index_live, ~p"/members/new")

      assert index_live
             |> form("#member-form", member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#member-form", member: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/members")

      html = render(index_live)
      assert html =~ "Member created successfully"
    end

    test "updates member in listing", %{conn: conn, member: member} do
      {:ok, index_live, _html} = live(conn, ~p"/members")

      assert index_live |> element("#members-#{member.id} a", "Edit") |> render_click() =~
               "Edit Member"

      assert_patch(index_live, ~p"/members/#{member}/edit")

      assert index_live
             |> form("#member-form", member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#member-form", member: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/members")

      html = render(index_live)
      assert html =~ "Member updated successfully"
    end

    test "deletes member in listing", %{conn: conn, member: member} do
      {:ok, index_live, _html} = live(conn, ~p"/members")

      assert index_live |> element("#members-#{member.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#members-#{member.id}")
    end
  end

  describe "Show" do
    setup [:create_member]

    test "displays member", %{conn: conn, member: member} do
      {:ok, _show_live, html} = live(conn, ~p"/members/#{member}")

      assert html =~ "Show Member"
    end

    test "updates member within modal", %{conn: conn, member: member} do
      {:ok, show_live, _html} = live(conn, ~p"/members/#{member}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Member"

      assert_patch(show_live, ~p"/members/#{member}/show/edit")

      assert show_live
             |> form("#member-form", member: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#member-form", member: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/members/#{member}")

      html = render(show_live)
      assert html =~ "Member updated successfully"
    end
  end
end
