defmodule Itsm.Categories do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Category

  def list_categories do
    Repo.all(Category)
  end

  def filter_categories(filter) do
    Category
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> sort(filter["sort_by"])
    |> Repo.all()
  end

  defp with_type(query, group) when group in ~w(K_리전_공동존 K_리전_은행존 P_리전 배치자동화) do
    where(query, group: ^group)
  end

  defp with_type(query, _), do: query

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword) do
    where(query, [c], ilike(c.name, ^"%#{keyword}%"))
  end

  defp sort(query, "name") do
    order_by(query, :name)
  end

  defp sort(query, "description_desc") do
    order_by(query, desc: :description)
  end

  defp sort(query, "description_asc") do
    order_by(query, asc: :description)
  end

  defp sort(query, _) do
    order_by(query, :id)
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
