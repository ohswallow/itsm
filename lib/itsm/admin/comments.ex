defmodule Itsm.Admin.Comments do
  import Ecto.Query, warn: false
  alias Itsm.Admin.Requests
  alias Itsm.Repo
  alias Itsm.Comments.Comment

  def get_comment!(id), do: Repo.get!(Comment, id)

  def change_comment(comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  defdelegate create_comment(resource, user, attrs \\ %{}), to: Itsm.Comments

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, comment} ->
        event = :update_comment
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcast(Requests, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcasts(Requests, {attrs["current_user"], event, comment})
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_comment(%{"id" => id} = attrs) do
    Repo.delete(get_comment!(id))
    |> case do
      {:ok, comment} ->
        event = :delete_comment
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcast(Requests, {attrs["current_user"], event, comment})
        Itsm.Utils.broadcasts(Requests, {attrs["current_user"], event, comment})
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate with_assoc(comment, preloads), to: Itsm.Comments
end
