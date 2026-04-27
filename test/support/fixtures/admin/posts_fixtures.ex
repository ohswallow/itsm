defmodule Itsm.Admin.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Admin.Posts` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        content: "some content",
        metadata: %{},
        title: "some title"
      })
      |> Itsm.Admin.Posts.create_post(%{}, %{})

    post
  end
end
