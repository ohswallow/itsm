defmodule Itsm.Admin.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Posts.Post
  alias Itsm.Admin.Attachments

  def get_post!(id), do: Repo.get!(Post, id)

  def create_post(%User{} = action_user, attrs, selected_board_metadata, repo \\ Repo, opts \\ []) do
    %Post{}
    |> change_post(
      attrs: attrs,
      action_user: action_user,
      selected_board_metadata: selected_board_metadata
    )
    |> repo.insert()
    |> case do
      {:ok, post} ->
        post = post |> repo.preload(:author)

        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_post, post})
        end

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_post(
        %User{} = action_user,
        %Post{} = post,
        attrs,
        selected_board_metadata,
        repo \\ Repo,
        opts \\ []
      ) do
    post
    |> change_post(
      attrs: attrs,
      action_user: action_user,
      selected_board_metadata: selected_board_metadata,
      call_back: &Itsm.Utils.maybe_put_change(&1, :inserted_at, attrs["inserted_at"])
    )
    |> repo.update()
    |> case do
      {:ok, post} ->
        post = post |> repo.preload(:author)

        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_post, post}, id: post.id)
        end

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_post(%User{} = action_user, %{"id" => id}) do
    get_post!(id)
    |> Repo.delete()
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

  def with_assoc(%Post{} = post, preloads), do: Repo.preload(post, preloads)

  def save_with_attachment(
        :edit,
        %User{} = action_user,
        %Post{} = post,
        attrs,
        selected_board_metadata,
        consumer_fn
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:update_post, fn repo, _ ->
      update_post(action_user, post, attrs, selected_board_metadata, repo, broadcast: false)
    end)
    |> Ecto.Multi.run(:create_attachments, fn repo, %{update_post: post} ->
      Attachments.create_attachments(action_user, post, consumer_fn, repo, broadcast: false)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{update_post: post, create_attachments: attachments}} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_post, post}, id: post.id)
        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachments})

        {:ok, post}
    end
  end

  def save_with_attachment(
        :new,
        %User{} = action_user,
        %{},
        attrs,
        selected_board_metadata,
        consumer_fn
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:create_post, fn repo, _ ->
      create_post(action_user, attrs, selected_board_metadata, repo, broadcast: false)
    end)
    |> Ecto.Multi.run(:create_attachments, fn repo, %{create_post: post} ->
      Attachments.create_attachments(action_user, post, consumer_fn, repo, broadcast: false)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{create_post: post, create_attachments: attachments}} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_post, post})
        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachments})

        {:ok, post}

      error ->
        error
    end
  end
end
