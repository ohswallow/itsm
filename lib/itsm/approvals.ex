defmodule Itsm.Approvals do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Service.Approval
  alias Itsm.Service.Request

  @doc """
  Returns the list of approvals.

  ## Examples

      iex> list_approvals()
      [%Approval{}, ...]

  """
  def list_approvals do
    Repo.all(Approval)
  end

  @doc """
  Gets a single approval.

  Raises `Ecto.NoResultsError` if the Approval does not exist.

  ## Examples

      iex> get_approval!(123)
      %Approval{}

      iex> get_approval!(456)
      ** (Ecto.NoResultsError)

  """
  def get_approval!(id), do: Repo.get!(Approval, id)

  @doc """
  Creates a approval.

  ## Examples

      iex> create_approval(%{field: value})
      {:ok, %Approval{}}

      iex> create_approval(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_approval(attrs \\ %{}) do
    %Approval{}
    |> Approval.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a approval.

  ## Examples

      iex> update_approval(approval, %{field: new_value})
      {:ok, %Approval{}}

      iex> update_approval(approval, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_approval(%Approval{} = approval, attrs) do
    approval
    |> Approval.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a approval.

  ## Examples

      iex> delete_approval(approval)
      {:ok, %Approval{}}

      iex> delete_approval(approval)
      {:error, %Ecto.Changeset{}}

  """
  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking approval changes.

  ## Examples

      iex> change_approval(approval)
      %Ecto.Changeset{data: %Approval{}}

  """
  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
  end

  def create_approval(repo, %Request{} = request, %User{} = user) do
    %Approval{
      approver: user,
      approver_name: user.display_name,
      request: request
    }
    |> Approval.changeset(%{})
    |> repo.insert()
  end
end
