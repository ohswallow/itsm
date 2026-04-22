defmodule ItsmWeb.Admin.UserLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.Admin.AccountsFixtures

  @create_attrs %{password: "some password", role: "some role", organization: "some organization", email: "some email", hashed_password: "some hashed_password", current_password: "some current_password", confirmed_at: "2026-04-19T07:59:00Z", employee_number: "some employee_number", display_name: "some display_name", organization_code: "some organization_code", department: "some department", department_code: "some department_code"}
  @update_attrs %{password: "some updated password", role: "some updated role", organization: "some updated organization", email: "some updated email", hashed_password: "some updated hashed_password", current_password: "some updated current_password", confirmed_at: "2026-04-20T07:59:00Z", employee_number: "some updated employee_number", display_name: "some updated display_name", organization_code: "some updated organization_code", department: "some updated department", department_code: "some updated department_code"}
  @invalid_attrs %{password: nil, role: nil, organization: nil, email: nil, hashed_password: nil, current_password: nil, confirmed_at: nil, employee_number: nil, display_name: nil, organization_code: nil, department: nil, department_code: nil}

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  describe "Index" do
    setup [:create_user]

    test "lists all users", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/users")

      assert html =~ "Listing Users"
      assert html =~ user.password
    end

    test "saves new user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("a", "New User") |> render_click() =~
               "New User"

      assert_patch(index_live, ~p"/admin/users/new")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user-form", user: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")

      html = render(index_live)
      assert html =~ "User created successfully"
      assert html =~ "some password"
    end

    test "updates user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#users-#{user.id} a", "Edit") |> render_click() =~
               "Edit User"

      assert_patch(index_live, ~p"/admin/users/#{user}/edit")

      assert index_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user-form", user: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/users")

      html = render(index_live)
      assert html =~ "User updated successfully"
      assert html =~ "some updated password"
    end

    test "deletes user in listing", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/users")

      assert index_live |> element("#users-#{user.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#users-#{user.id}")
    end
  end

  describe "Show" do
    setup [:create_user]

    test "displays user", %{conn: conn, user: user} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/users/#{user}")

      assert html =~ "Show User"
      assert html =~ user.password
    end

    test "updates user within modal", %{conn: conn, user: user} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/users/#{user}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit User"

      assert_patch(show_live, ~p"/admin/users/#{user}/show/edit")

      assert show_live
             |> form("#user-form", user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#user-form", user: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/users/#{user}")

      html = render(show_live)
      assert html =~ "User updated successfully"
      assert html =~ "some updated password"
    end
  end
end
