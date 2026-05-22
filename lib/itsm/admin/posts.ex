defmodule Itsm.Admin.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Posts.Post

  defdelegate get_post!(id), to: Itsm.Posts

  defdelegate list_posts, to: Itsm.Posts

  defdelegate create_post(action_user, attrs, selected_board_metadata, repo \\ Repo),
    to: Itsm.Posts

  def update_post(
        %User{} = action_user,
        %Post{} = post,
        attrs,
        selected_board_metadata,
        repo \\ Repo
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
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_post, post}, id: post.id)

        {:ok, post}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate delete_post(action_user, attrs), to: Itsm.Posts

  defdelegate change_post(post, opts \\ []), to: Itsm.Posts

  defdelegate with_assoc(post, preloads), to: Itsm.Posts

  defdelegate save_with_attachment(
                action,
                action_user,
                post,
                attrs,
                selected_board_metadata,
                consumer_fn
              ),
              to: Itsm.Posts
end
