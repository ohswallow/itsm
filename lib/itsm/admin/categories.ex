defmodule Itsm.Admin.Categories do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Category

  defdelegate get_category!(id), to: Itsm.Categories

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, category} ->
        Itsm.Utils.broadcasts(:category, {:create_Category, category})
        {:ok, category}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, category} ->
        Itsm.Utils.broadcast(:category, {:update_category, category})
        Itsm.Utils.broadcasts(:categories, {:update_category, category})
        {:ok, category}

      {:error, _} = error ->
        error
    end
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
    |> case do
      {:ok, category} ->
        Itsm.Utils.broadcast(:category, {:delete_category, category})
        Itsm.Utils.broadcasts(:categories, {:delete_category, category})
        {:ok, category}

      {:error, _} = error ->
        error
    end
  end

  def get_category_options do
    Category
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end
end
