defmodule Itsm.Attachments do
  import Ecto.Query, warn: false

  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Utils
  alias Itsm.Attachments.Attachment

  def get_attachment!(id) do
    Attachment
    |> Repo.get!(id)
  end

  def get_list_attachments(resource) do
    Attachment
    |> where([a], a.resource_type == ^Utils.resource_name(resource))
    |> where([a], a.resource_id == ^resource.id)
    |> where([a], a.status == :active)
    |> Repo.all()
  end

  def create_attachment(%User{} = action_user, attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, attachment} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_attachments, attachment})

        {:ok, attachment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_attachments(%User{} = action_user, repo, resource, consumer_fn) do
    attachments = consumer_fn.()

    Enum.reduce_while(attachments, {:ok, []}, fn attrs, {:ok, acc} ->
      %Attachment{resource_type: Utils.resource_name(resource), resource_id: resource.id}
      |> Attachment.changeset(attrs)
      |> repo.insert()
      |> case do
        {:ok, attachment} ->
          Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_attachments, attachment})

          {:cont, {:ok, [attachment | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  def delete_attachment(%User{} = action_user, id) do
    get_attachment!(id)
    |> Attachment.delete_changeset()
    |> Repo.update()
    |> case do
      {:ok, attachment} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_attachment, attachment},
          id: attachment.id
        )

        {:ok, attachment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def active_attachment(), do: Attachment |> where([a], a.status == :active)
end
