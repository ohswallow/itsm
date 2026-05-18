defmodule Itsm.Admin.Attachments do
  @moduledoc """
  The Attachments context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Attachments.Attachment

  defdelegate get_attachment!(id), to: Itsm.Attachments

  def list_attachments_by_resource(resource) do
    Attachment
    |> where([a], a.resource_type == ^Itsm.Utils.resource_name(resource))
    |> where([a], a.resource_id == ^resource.id)
    |> Repo.all()
  end

  defdelegate create_attachment(action_user, attrs), to: Itsm.Attachments

  def update_attachment(%User{} = action_user, %Attachment{} = attachment, attrs) do
    attachment
    |> Attachment.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, attachment} ->
        attachment.broadcast(__MODULE__, {action_user, :update_attachment, attachment},
          id: attachment.id
        )

        {:ok, attachment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate delete_attachment(action_user, attrs), to: Itsm.Attachments

  def change_attachment(%Attachment{} = attachment, attrs \\ %{}) do
    Attachment.changeset(attachment, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
end
