defmodule Itsm.Admin.AttachmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Admin.Attachments` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a attachment.
  """
  def attachment_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        byte_size: 42,
        deleted_at: ~U[2026-05-14 05:26:00Z],
        file_type: "some file_type",
        filename: "some filename",
        local_path: "some local_path",
        resource_id: "7488a646-e31f-11e4-aace-600308960662",
        resource_type: "some resource_type",
        status: "some status"
      })

    {:ok, attachment} = Itsm.Admin.Attachments.create_attachment(%User{}, attrs)

    attachment
  end
end
