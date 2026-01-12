defmodule Itsm.Attachments do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Attachments.Attachment

  @doc """
  Creates an attachment.

  ## Examples

      iex> create_attachment(%{field: value})
      {:ok, %Attachment{}}

      iex> create_attachment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_attachment(attrs \\ %{}) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end
end
