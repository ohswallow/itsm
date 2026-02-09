defmodule Itsm.Attachments do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Util
  alias Itsm.Attachments.Attachment

  def get_attachment!(id) do
    Attachment
    |> Repo.get!(id)
  end

  def create_attachment(attrs \\ %{}) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end

  def create_attachments(repo, resource, attachments_callback) do
    attachments = attachments_callback.()

    Enum.reduce_while(attachments, {:ok, []}, fn attrs, {:ok, acc} ->
      %Attachment{resource_type: Util.resource_name(resource), resource_id: resource.id}
      |> Attachment.changeset(attrs)
      |> repo.insert()
      |> case do
        {:ok, attachment} ->
          {:cont, {:ok, [attachment | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end
end
