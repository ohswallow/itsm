defmodule Itsm.Admin.AttachmentsTest do
  use Itsm.DataCase

  alias Itsm.Admin.Attachments

  describe "attachments" do
    alias Itsm.Attachments.Attachment

    import Itsm.Admin.AttachmentsFixtures

    @invalid_attrs %{status: nil, byte_size: nil, filename: nil, local_path: nil, file_type: nil, resource_type: nil, resource_id: nil, deleted_at: nil}

    test "list_attachments/0 returns all attachments" do
      attachment = attachment_fixture()
      assert Attachments.list_attachments() == [attachment]
    end

    test "get_attachment!/1 returns the attachment with given id" do
      attachment = attachment_fixture()
      assert Attachments.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates a attachment" do
      valid_attrs = %{status: "some status", byte_size: 42, filename: "some filename", local_path: "some local_path", file_type: "some file_type", resource_type: "some resource_type", resource_id: "7488a646-e31f-11e4-aace-600308960662", deleted_at: ~U[2026-05-14 05:26:00Z]}

      assert {:ok, %Attachment{} = attachment} = Attachments.create_attachment(valid_attrs)
      assert attachment.status == "some status"
      assert attachment.byte_size == 42
      assert attachment.filename == "some filename"
      assert attachment.local_path == "some local_path"
      assert attachment.file_type == "some file_type"
      assert attachment.resource_type == "some resource_type"
      assert attachment.resource_id == "7488a646-e31f-11e4-aace-600308960662"
      assert attachment.deleted_at == ~U[2026-05-14 05:26:00Z]
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attachments.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      attachment = attachment_fixture()
      update_attrs = %{status: "some updated status", byte_size: 43, filename: "some updated filename", local_path: "some updated local_path", file_type: "some updated file_type", resource_type: "some updated resource_type", resource_id: "7488a646-e31f-11e4-aace-600308960668", deleted_at: ~U[2026-05-15 05:26:00Z]}

      assert {:ok, %Attachment{} = attachment} = Attachments.update_attachment(attachment, update_attrs)
      assert attachment.status == "some updated status"
      assert attachment.byte_size == 43
      assert attachment.filename == "some updated filename"
      assert attachment.local_path == "some updated local_path"
      assert attachment.file_type == "some updated file_type"
      assert attachment.resource_type == "some updated resource_type"
      assert attachment.resource_id == "7488a646-e31f-11e4-aace-600308960668"
      assert attachment.deleted_at == ~U[2026-05-15 05:26:00Z]
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      attachment = attachment_fixture()
      assert {:error, %Ecto.Changeset{}} = Attachments.update_attachment(attachment, @invalid_attrs)
      assert attachment == Attachments.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{}} = Attachments.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      attachment = attachment_fixture()
      assert %Ecto.Changeset{} = Attachments.change_attachment(attachment)
    end
  end
end
