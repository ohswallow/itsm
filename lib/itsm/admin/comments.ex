defmodule Itsm.Admin.Comments do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Comments.Comment

  def list_comments do
    Repo.all(Comment)
    |> Repo.preload([:user])
  end

  def get_comment!(id), do: Repo.get!(Comment, id) |> Repo.preload([:user])

  defdelegate change_comment(comment, attrs \\ %{}), to: Itsm.Comments

  defdelegate create_comment(resource, user, attrs \\ %{}), to: Itsm.Comments

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end
end
