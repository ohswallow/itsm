defmodule Itsm.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Comments.Comment
  alias Itsm.Accounts.User
  alias Itsm.Attachments.Attachment
  alias Ecto.Multi
  alias Itsm.Requests

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
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

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  # def create_comment(%Request{} = request, %User{} = user, attrs \\ %{}) do
  #   %Comment{request: request, user: user}
  #   |> Comment.changeset(attrs)
  #   |> Repo.insert()
  #   |> case do
  #     {:ok, comment} ->
  #       Service.broadcast_request(request.id, {:comment_created, comment})
  #       {:ok, comment}

  #     {:error, _} = error ->
  #       error
  #   end
  # end

  def create_comment(resource, %User{} = user, attrs \\ %{}) do
    # 1. 첨부파일 분리
    {attachments, comment_attrs} = Map.pop(attrs, "attachments", [])

    # 2. 넘겨받은 Type과 ID를 그대로 사용
    comment_params =
      Map.merge(comment_attrs, %{
        "resource_type" => get_resource_type(resource),
        "resource_id" => resource.id
      })

    Multi.new()
    |> Multi.insert(:comment, Comment.changeset(%Comment{user: user}, comment_params))
    |> insert_attachments(attachments)
    |> Repo.transaction()
    |> broadcast_result(resource.id)
  end

  # 구조체의 모듈명을 분석해 마지막 이름 추출
  # 예: Itsm.Service.Request -> "Request"
  # 나중에 Incident가 들어오면 자동으로 "Incident"가 됨. 스키마 수정 불필요.
  defp get_resource_type(struct) do
    struct.__struct__
    |> Module.split()
    |> List.last()
  end

  # 첨부파일이 없으면 Multi 그대로 통과
  defp insert_attachments(multi, []), do: multi

  # 첨부파일이 있으면 Multi.run 실행
  defp insert_attachments(multi, attachments) do
    Multi.run(multi, :attachments, fn repo, %{comment: comment} ->
      save_attachments_to_db(repo, comment, attachments)
    end)
  end

  defp save_attachments_to_db(repo, comment, attachments) do
    results =
      Enum.map(attachments, fn attachment_attrs ->
        # Commnet에 첨부한 파일은 Comment 소속
        attrs =
          Map.merge(attachment_attrs, %{
            "resource_type" => get_resource_type(comment),
            "resource_id" => comment.id
          })

        %Attachment{} |> Attachment.changeset(attrs) |> repo.insert()
      end)

    # 하나라도 실패하면 에러 리턴
    if Enum.all?(results, &match?({:ok, _}, &1)), do: {:ok, results}, else: {:error, :failed}
  end

  # 결과 처리
  defp broadcast_result({:ok, %{comment: comment}}, topic_id) do
    comment = Repo.preload(comment, :attachments)
    # PubSub 방송 (토픽 ID로 전파)
    Requests.broadcast_request(topic_id, {:comment_created, comment})
    {:ok, comment}
  end

  defp broadcast_result({:error, _, failed, _}, _), do: {:error, failed}

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
