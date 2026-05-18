defmodule Itsm.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Posts.Post

  def get_post!(id), do: Repo.get!(Post, id)

  def list_posts, do: Repo.all(Post)

  def list_posts_by_board_id(board_id),
    do: Post |> where([p], p.board_id == ^board_id) |> preload(:author) |> Repo.all()

  def create_post(%User{} = action_user, attrs, selected_board_metadata) do
    %Post{}
    |> change_post(
      attrs: attrs,
      action_user: action_user,
      selected_board_metadata: selected_board_metadata
    )
    |> Repo.insert()
    |> case do
      {:ok, post} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_post, post})
        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_post(%User{} = action_user, %Post{} = post, attrs, selected_board_metadata) do
    post
    |> change_post(
      attrs: attrs,
      action_user: action_user,
      selected_board_metadata: selected_board_metadata
    )
    |> Repo.update()
    |> case do
      {:ok, post} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_post, post}, id: post.id)

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_post(%User{} = action_user, %{"id" => id}) do
    Repo.delete(get_post!(id))
    |> case do
      {:ok, post} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_post, post}, id: post.id)

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_post(%Post{} = post, opts \\ []) when is_list(opts) do
    attrs = Keyword.get(opts, :attrs, %{})
    action_user = Keyword.get(opts, :action_user, %{})
    selected_board_metadata = Keyword.get(opts, :selected_board_metadata, %{})
    call_back = Keyword.get(opts, :call_back, & &1)

    post
    |> Post.changeset(attrs, action_user, selected_board_metadata)
    |> call_back.()
  end

  def with_assoc(%Post{} = post, preloads) do
    Repo.preload(post, preloads)
  end
end
