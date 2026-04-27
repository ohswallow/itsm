defmodule Itsm.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Posts.Post

  def get_post!(id), do: Repo.get!(Post, id)

  def list_posts, do: Repo.all(Post)

  def list_posts_by_board_id(board_id),
    do: Post |> where([p], p.board_id == ^board_id) |> preload(:author) |> Repo.all()

  def create_post(attrs, current_user, selected_board_metadata) do
    %Post{}
    |> change_post(
      attrs: attrs,
      current_user: current_user,
      selected_board_metadata: selected_board_metadata
    )
    |> Repo.insert()
    |> case do
      {:ok, post} ->
        Itsm.Utils.broadcasts(__MODULE__, {current_user, :create_post, post})
        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_post(%Post{} = post, attrs, current_user, selected_board_metadata) do
    post
    |> change_post(
      attrs: attrs,
      current_user: current_user,
      selected_board_metadata: selected_board_metadata
    )
    |> Repo.update()
    |> case do
      {:ok, post} ->
        Itsm.Utils.broadcast(__MODULE__, {current_user, :update_post, post})
        Itsm.Utils.broadcasts(__MODULE__, {current_user, :update_post, post})
        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_post(%{"id" => id}, current_user \\ %{}) do
    Repo.delete(get_post!(id))
    |> case do
      {:ok, post} ->
        Itsm.Utils.broadcast(Post, {current_user, :delete_post, post})
        Itsm.Utils.broadcasts(Post, {current_user, :delete_post, post})
        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_post(%Post{} = post, opts \\ []) when is_list(opts) do
    attrs = Keyword.get(opts, :attrs, %{})
    current_user = Keyword.get(opts, :current_user, %{})
    selected_board_metadata = Keyword.get(opts, :selected_board_metadata, %{})
    call_back = Keyword.get(opts, :call_back, & &1)

    post
    |> Post.changeset(attrs, current_user, selected_board_metadata)
    |> call_back.()
  end

  def with_assoc(%Post{} = post, preloads) do
    Repo.preload(post, preloads)
  end
end
