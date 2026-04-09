defmodule Itsm.OsInstances do
  @moduledoc """
  The OsInstances context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.OsInstances.OsInstance

  @doc """
  Returns the list of os_instances.

  ## Examples

      iex> list_os_instances()
      [%OsInstance{}, ...]

  """
  def list_os_instances do
    Repo.all(OsInstance)
  end

  @doc """
  Gets a single os_instance.

  Raises `Ecto.NoResultsError` if the Os instance does not exist.

  ## Examples

      iex> get_os_instance!(123)
      %OsInstance{}

      iex> get_os_instance!(456)
      ** (Ecto.NoResultsError)

  """
  def get_os_instance!(id), do: Repo.get!(OsInstance, id)

  @doc """
  Creates a os_instance.

  ## Examples

      iex> create_os_instance(%{field: value})
      {:ok, %OsInstance{}}

      iex> create_os_instance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_os_instance(attrs \\ %{}) do
    %OsInstance{}
    |> OsInstance.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, os_istance} ->
        Itsm.Utils.broadcasts(
          __MODULE__,
          {attrs["current_user"], :create_os_instance, os_istance}
        )

        {:ok, os_istance}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a os_instance.

  ## Examples

      iex> update_os_instance(os_instance, %{field: new_value})
      {:ok, %OsInstance{}}

      iex> update_os_instance(os_instance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_os_instance(%OsInstance{} = os_instance, attrs) do
    os_instance
    |> OsInstance.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, os_istance} ->
        Itsm.Utils.broadcast(
          __MODULE__,
          {attrs["current_user"], :update_os_instance, os_istance}
        )

        Itsm.Utils.broadcasts(
          __MODULE__,
          {attrs["current_user"], :update_os_instance, os_istance}
        )

        {:ok, os_istance}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a os_instance.

  ## Examples

      iex> delete_os_instance(os_instance)
      {:ok, %OsInstance{}}

      iex> delete_os_instance(os_instance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_os_instance(%{"id" => id}, attrs) do
    Repo.delete(get_os_instance!(id))
    |> case do
      {:ok, os_istance} ->
        Itsm.Utils.broadcast(
          __MODULE__,
          {attrs["current_user"], :delete_os_instance, os_istance}
        )

        Itsm.Utils.broadcasts(
          __MODULE__,
          {attrs["current_user"], :delete_os_instance, os_istance}
        )

        {:ok, os_istance}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking os_instance changes.

  ## Examples

      iex> change_os_instance(os_instance)
      %Ecto.Changeset{data: %OsInstance{}}

  """
  def change_os_instance(%OsInstance{} = os_instance, attrs \\ %{}) do
    OsInstance.changeset(os_instance, attrs)
  end
end
