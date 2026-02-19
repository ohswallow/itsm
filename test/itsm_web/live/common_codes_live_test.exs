defmodule ItsmWeb.CodesLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.CommonFixtures

  @create_attrs %{
    code: "some code",
    label: "some label",
    description: "some description",
    group_code: "some group_code",
    sort_order: 42,
    is_active: true
  }
  @update_attrs %{
    code: "some updated code",
    label: "some updated label",
    description: "some updated description",
    group_code: "some updated group_code",
    sort_order: 43,
    is_active: false
  }
  @invalid_attrs %{
    code: nil,
    label: nil,
    description: nil,
    group_code: nil,
    sort_order: nil,
    is_active: false
  }

  defp create_common_codes(_) do
    common_codes = common_codes_fixture()
    %{common_codes: common_codes}
  end

  describe "Index" do
    setup [:create_common_codes]

    test "lists all common_codes", %{conn: conn, common_codes: common_codes} do
      {:ok, _index_live, html} = live(conn, ~p"/common_codes")

      assert html =~ "Listing Common codes"
      assert html =~ common_codes.code
    end

    test "saves new codes", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/common_codes")

      assert index_live |> element("a", "New Common Codes") |> render_click() =~
               "New Common Codes"

      assert_patch(index_live, ~p"/common_codes/new")

      assert index_live
             |> form("#common_codes-form", common_codes: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#common_codes-form", common_codes: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/common_codes")

      html = render(index_live)
      assert html =~ "Common codes created successfully"
      assert html =~ "some code"
    end

    test "updates common_codes in listing", %{conn: conn, common_codes: common_codes} do
      {:ok, index_live, _html} = live(conn, ~p"/common_codes")

      assert index_live |> element("#common_codes-#{common_codes.id} a", "Edit") |> render_click() =~
               "Edit Common Codes"

      assert_patch(index_live, ~p"/common_codes/#{common_codes}/edit")

      assert index_live
             |> form("#common_codes-form", common_codes: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#common_codes-form", common_codes: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/common_codes")

      html = render(index_live)
      assert html =~ "Common codes updated successfully"
      assert html =~ "some updated code"
    end

    test "deletes common_codes in listing", %{conn: conn, common_codes: common_codes} do
      {:ok, index_live, _html} = live(conn, ~p"/common_codes")

      assert index_live
             |> element("#common_codes-#{common_codes.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#common_codes-#{common_codes.id}")
    end
  end

  describe "Show" do
    setup [:create_common_codes]

    test "displays common_codes", %{conn: conn, common_codes: common_codes} do
      {:ok, _show_live, html} = live(conn, ~p"/common_codes/#{common_codes}")

      assert html =~ "Show Common Codes"
      assert html =~ common_codes.code
    end

    test "updates common_codes within modal", %{conn: conn, common_codes: common_codes} do
      {:ok, show_live, _html} = live(conn, ~p"/common_codes/#{common_codes}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Common Codes"

      assert_patch(show_live, ~p"/common_codes/#{common_codes}/show/edit")

      assert show_live
             |> form("#common_codes-form", common_codes: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#common_codes-form", common_codes: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/common_codes/#{common_codes}")

      html = render(show_live)
      assert html =~ "Common codes updated successfully"
      assert html =~ "some updated common code"
    end
  end
end
