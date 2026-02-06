defmodule Itsm.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Comments.Comment
  alias Itsm.Accounts.User
  alias Itsm.Requests
  alias Itsm.Util

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  def list_comments(resource) do
    Comment
    # "Request"
    |> where([c], c.resource_type == ^Util.resource_name(resource))
    # ID 매칭
    |> where([c], c.resource_id == ^resource.id)
    |> order_by([c], asc: c.inserted_at)
    # 첨부파일/작성자 로딩
    |> preload([:user, :attachments])
    |> Repo.all()
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  def create_comment(resource, %User{} = user, attrs \\ %{}) do
    changeset_comment(resource, user, attrs)
    |> Repo.insert()
  end

  def changeset_comment(resource, %User{} = user, attrs \\ %{}) do
    %Comment{
      user: user,
      resource_type: Util.resource_name(resource),
      resource_id: resource.id
    }
    |> Comment.changeset(attrs)
  end

  # 결과 처리
  def broadcast_result({:ok, %{comment: comment}}, topic_id) do
    comment = Repo.preload(comment, :attachments)
    # PubSub 방송 (토픽 ID로 전파)
    Requests.broadcast_request(topic_id, {:comment_created, comment})
    {:ok, comment}
  end

  def broadcast_result({:error, _, failed, _}, _), do: {:error, failed}

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end
