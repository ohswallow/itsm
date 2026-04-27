defmodule Itsm.Admin.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Posts.Post

  defdelegate get_post!(id), to: Itsm.Posts

  defdelegate list_posts, to: Itsm.Posts

  defdelegate create_post(attrs, current_user, selected_board_metadata), to: Itsm.Posts

  def update_post(%Post{} = post, attrs, current_user, selected_board_metadata) do
    post
    |> change_post(
      attrs: attrs,
      current_user: current_user,
      selected_board_metadata: selected_board_metadata,
      call_back: &Itsm.Utils.maybe_put_change(&1, :inserted_at, attrs["inserted_at"])
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

  defdelegate delete_post(attrs), to: Itsm.Posts

  defdelegate change_post(post, opts \\ []), to: Itsm.Posts

  defdelegate with_assoc(post, preloads), to: Itsm.Posts
end
