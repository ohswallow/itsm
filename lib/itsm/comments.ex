defmodule Itsm.Comments do
  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Comments.Comment
  alias Itsm.Accounts.User
  alias Itsm.Requests
  alias Itsm.Utils

  # 결과 처리
  def broadcast_result({:ok, %{comment: comment}}, topic_id) do
    comment = Repo.preload(comment, :attachments)
    # PubSub 방송 (토픽 ID로 전파)
    Requests.broadcast_request(topic_id, {:comment_created, comment})
    {:ok, comment}
  end

  def broadcast_result({:error, _, failed, _}, _), do: {:error, failed}

  def list_comments(resource) do
    Comment
    # "Request"
    |> where([c], c.resource_type == ^Utils.resource_name(resource))
    # ID 매칭
    |> where([c], c.resource_id == ^resource.id)
    |> order_by([c], asc: c.inserted_at)
    # 첨부파일/작성자 로딩
    |> preload([:user, :attachments])
    |> Repo.all()
  end

  def changeset_comment(resource, %User{} = user, attrs \\ %{}) do
    %Comment{
      user: user,
      resource_type: Utils.resource_name(resource),
      resource_id: resource.id
    }
    |> Comment.changeset(attrs)
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def create_comment(resource, %User{} = user, attrs \\ %{}) do
    changeset_comment(resource, user, attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        # 🌟 1. Show.ex 화면을 위해 :user와 :attachments 둘 다 Preload!
        preloaded_comment = Repo.preload(comment, [:user, :attachments])

        # 🌟 2. 여기서 직접 PubSub 방송을 쏩니다! (기존 로직 활용)
        Requests.broadcast_request(resource.id, {:comment_created, preloaded_comment})

        {:ok, preloaded_comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
