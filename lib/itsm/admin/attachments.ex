defmodule Itsm.Admin.Attachments do
  @moduledoc """
  The Attachments context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Attachments.Attachment

  def get_attachment!(id), do: Attachment |> Repo.get!(id)

  def list_attachments_by_resource_is_active(resource) do
    Attachment
    |> where([a], a.resource_type == ^Itsm.Utils.resource_name(resource))
    |> where([a], a.resource_id == ^resource.id)
    |> where([a], a.status == :active)
    |> Repo.all()
  end

  def list_attachments_by_resource(resource) do
    Attachment
    |> where([a], a.resource_type == ^Itsm.Utils.resource_name(resource))
    |> where([a], a.resource_id == ^resource.id)
    |> Repo.all()
  end

  def create_attachment(%User{} = action_user, attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, attachment} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_attachment, attachment})

        {:ok, attachment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_attachments(%User{} = action_user, resource, consumer_fn, repo \\ Repo, opts \\ []) do
    consumer_fn.()
    |> Enum.reduce_while({:ok, []}, fn attrs, {:ok, acc} ->
      %Attachment{}
      |> Attachment.create_changeset(resource, attrs)
      |> repo.insert()
      |> case do
        {:ok, attachment} -> {:cont, {:ok, [attachment | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, attachments} ->
        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(
            __MODULE__,
            {action_user, :create_attachments, attachments}
          )
        end

        {:ok, attachments}

      error ->
        error
    end
  end

  def update_attachment(%User{} = action_user, %Attachment{} = attachment, attrs) do
    attachment
    |> Attachment.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, attachment} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_attachment, attachment},
          id: attachment.id
        )

        {:ok, attachment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_attachment(%User{} = action_user, %{"id" => id}) do
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

  def change_attachment(%Attachment{} = attachment, attrs \\ %{}) do
    Attachment.changeset(attachment, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
end
