defmodule Itsm.Comments do
  import Ecto.Query, warn: false
  alias Itsm.Requests
  alias Itsm.Repo

  alias Itsm.Comments.Comment
  alias Itsm.Accounts.User
  alias Itsm.Utils

  def list_comments_by_resource(resource) do
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

  def changeset_comment(%User{} = action_user, resource, attrs \\ %{}) do
    %Comment{
      user: action_user,
      resource_type: Utils.resource_name(resource),
      resource_id: resource.id
    }
    |> Comment.changeset(attrs)
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  def create_comment(%User{} = action_user, resource, attrs \\ %{}) do
    changeset_comment(action_user, resource, attrs)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        # 🌟 1. Show.ex 화면을 위해 :user와 :attachments 둘 다 Preload!
        preloaded_comment = Repo.preload(comment, [:user, :attachments])

        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :create_comment, preloaded_comment},
          id: resource.id,
          only: :detail
        )

        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_comment, comment})

        {:ok, preloaded_comment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def with_assoc(%Comment{} = comment, preloads) do
    Repo.preload(comment, preloads)
  end
end
