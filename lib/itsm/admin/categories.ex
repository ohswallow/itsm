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
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def get_category_options do
    Category
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end
end
