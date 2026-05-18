defmodule ItsmWeb.Admin.AttachmentLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.Admin.AttachmentsFixtures

  @create_attrs %{status: "some status", byte_size: 42, filename: "some filename", local_path: "some local_path", file_type: "some file_type", resource_type: "some resource_type", resource_id: "7488a646-e31f-11e4-aace-600308960662", deleted_at: "2026-05-14T05:26:00Z"}
  @update_attrs %{status: "some updated status", byte_size: 43, filename: "some updated filename", local_path: "some updated local_path", file_type: "some updated file_type", resource_type: "some updated resource_type", resource_id: "7488a646-e31f-11e4-aace-600308960668", deleted_at: "2026-05-15T05:26:00Z"}
  @invalid_attrs %{status: nil, byte_size: nil, filename: nil, local_path: nil, file_type: nil, resource_type: nil, resource_id: nil, deleted_at: nil}

  defp create_attachment(_) do
    attachment = attachment_fixture()
    %{attachment: attachment}
  end

  describe "Index" do
    setup [:create_attachment]

    test "lists all attachments", %{conn: conn, attachment: attachment} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/attachments")

      assert html =~ "Listing Attachments"
      assert html =~ attachment.status
    end

    test "saves new attachment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/attachments")

      assert index_live |> element("a", "New Attachment") |> render_click() =~
               "New Attachment"

      assert_patch(index_live, ~p"/admin/attachments/new")

      assert index_live
             |> form("#attachment-form", attachment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#attachment-form", attachment: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/attachments")

      html = render(index_live)
      assert html =~ "Attachment created successfully"
      assert html =~ "some status"
    end

    test "updates attachment in listing", %{conn: conn, attachment: attachment} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/attachments")

      assert index_live |> element("#attachments-#{attachment.id} a", "Edit") |> render_click() =~
               "Edit Attachment"

      assert_patch(index_live, ~p"/admin/attachments/#{attachment}/edit")

      assert index_live
             |> form("#attachment-form", attachment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#attachment-form", attachment: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/attachments")

      html = render(index_live)
      assert html =~ "Attachment updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes attachment in listing", %{conn: conn, attachment: attachment} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/attachments")

      assert index_live |> element("#attachments-#{attachment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#attachments-#{attachment.id}")
    end
  end

  describe "Show" do
    setup [:create_attachment]

    test "displays attachment", %{conn: conn, attachment: attachment} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/attachments/#{attachment}")

      assert html =~ "Show Attachment"
      assert html =~ attachment.status
    end

    test "updates attachment within modal", %{conn: conn, attachment: attachment} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/attachments/#{attachment}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Attachment"

      assert_patch(show_live, ~p"/admin/attachments/#{attachment}/show/edit")

      assert show_live
             |> form("#attachment-form", attachment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#attachment-form", attachment: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/attachments/#{attachment}")

      html = render(show_live)
      assert html =~ "Attachment updated successfully"
      assert html =~ "some updated status"
    end
  end
end
