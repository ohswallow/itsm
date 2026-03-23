defmodule Itsm.Admin.Comments do
  import Ecto.Query, warn: false
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
        Itsm.Utils.broadcast(:comment, {:update_comment, comment})
        Itsm.Utils.broadcasts(:comments, {:update_comment, comment})
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
    |> case do
      {:ok, comment} ->
        Itsm.Utils.broadcast(:comment, {:delete_comment, comment})
        Itsm.Utils.broadcasts(:comments, {:delete_comment, comment})
        {:ok, comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def preload_user(%Comment{} = comment) do
    comment |> Repo.preload([:user])
  end
end
