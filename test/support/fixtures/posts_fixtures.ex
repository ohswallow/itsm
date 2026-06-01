defmodule Itsm.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Posts` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        content: "some content",
        metadata: %{},
        title: "some title"
      })

    {:ok, post} = Itsm.Posts.create_post(%User{}, attrs, %{})

    post
  end
end
