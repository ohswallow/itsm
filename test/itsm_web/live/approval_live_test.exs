defmodule ItsmWeb.ApprovalLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.ServiceFixtures

  @create_attrs %{
    status: :request,
    approver_id: "some approver_id",
    approver_name: "some approver_name",
    opnion: "some opnion"
  }
  @update_attrs %{
    status: :validation,
    approver_id: "some updated approver_id",
    approver_name: "some updated approver_name",
    opnion: "some updated opnion"
  }
  @invalid_attrs %{status: nil, approver_id: nil, approver_name: nil, opnion: nil}

  defp create_approval(_) do
    approval = approval_fixture()
    %{approval: approval}
  end

  describe "Index" do
    setup [:create_approval]

    test "lists all approvals", %{conn: conn, approval: approval} do
      {:ok, _index_live, html} = live(conn, ~p"/approvals")

      assert html =~ "Listing Approvals"
      assert html =~ approval.approver_id
    end

    test "saves new approval", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/approvals")

      assert index_live |> element("a", "New Approval") |> render_click() =~
               "New Approval"

      assert_patch(index_live, ~p"/approvals/new")

      assert index_live
             |> form("#approval-form", approval: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#approval-form", approval: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/approvals")

      html = render(index_live)
      assert html =~ "Approval created successfully"
      assert html =~ "some approver_id"
    end

    test "updates approval in listing", %{conn: conn, approval: approval} do
      {:ok, index_live, _html} = live(conn, ~p"/approvals")

      assert index_live |> element("#approvals-#{approval.id} a", "Edit") |> render_click() =~
               "Edit Approval"

      assert_patch(index_live, ~p"/approvals/#{approval}/edit")

      assert index_live
             |> form("#approval-form", approval: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#approval-form", approval: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/approvals")

      html = render(index_live)
      assert html =~ "Approval updated successfully"
      assert html =~ "some updated approver_id"
    end

    test "deletes approval in listing", %{conn: conn, approval: approval} do
      {:ok, index_live, _html} = live(conn, ~p"/approvals")

      assert index_live |> element("#approvals-#{approval.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#approvals-#{approval.id}")
    end
  end

  describe "Show" do
    setup [:create_approval]

    test "displays approval", %{conn: conn, approval: approval} do
      {:ok, _show_live, html} = live(conn, ~p"/approvals/#{approval}")

      assert html =~ "Show Approval"
      assert html =~ approval.approver_id
    end

    test "updates approval within modal", %{conn: conn, approval: approval} do
      {:ok, show_live, _html} = live(conn, ~p"/approvals/#{approval}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Approval"

      assert_patch(show_live, ~p"/approvals/#{approval}/show/edit")

      assert show_live
             |> form("#approval-form", approval: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#approval-form", approval: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/approvals/#{approval}")

      html = render(show_live)
      assert html =~ "Approval updated successfully"
      assert html =~ "some updated approver_id"
    end
  end
end
