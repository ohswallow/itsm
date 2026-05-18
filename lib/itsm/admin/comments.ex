defmodule Itsm.Admin.Comments do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Admin.Requests
  alias Itsm.Repo
  alias Itsm.Comments.Comment

  def get_comment!(id), do: Repo.get!(Comment, id)

  defdelegate list_comments_by_resource(resource), to: Itsm.Comments

  def change_comment(comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  defdelegate create_comment(action_user, resource, attrs), to: Itsm.Comments

  def update_comment(%User{} = action_user, %Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, comment} ->
        event = :update_comment
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, comment}, id: comment.id)
        Itsm.PubSub.Helper.broadcast(Requests, {action_user, event, comment}, id: comment.id)
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_comment(%User{} = action_user, %{"id" => id}) do
    Repo.delete(get_comment!(id))
    |> case do
      {:ok, comment} ->
        event = :delete_comment
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, comment}, id: comment.id)
        Itsm.PubSub.Helper.broadcast(Requests, {action_user, event, comment}, id: comment.id)
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate with_assoc(comment, preloads), to: Itsm.Comments
end
