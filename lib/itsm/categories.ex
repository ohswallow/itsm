defmodule Itsm.Categories do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Category

  @group_options_list [
    %{label: "K_리전_공동존", value: "K_리전_공동존"},
    %{label: "K_리전_은행존", value: "K_리전_은행존"},
    %{label: "배치자동화", value: "배치자동화"},
    %{label: "P_리전", value: "P_리전"}
  ]

  @sort_options_list [
    %{label: "이름 오름차순", value: "name_asc", order: [asc: :name]},
    %{label: "이름 내림차순", value: "name_desc", order: [desc: :name]}
  ]

  @sort_options_map_for_query Map.new(@sort_options_list, fn opt -> {opt.value, opt.order} end)

  def group_options, do: [{"그룹", ""}] ++ Enum.map(@group_options_list, &{&1.label, &1.value})

  def sort_options, do: Enum.map(@sort_options_list, &{&1.label, &1.value})

  def list_categories, do: Repo.all(Category)

  def filter_categories(filter) do
    Category
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> sort(filter["sort_by"])
    |> Repo.all()
  end

  def get_category_groups(%{"group" => group, "keyword" => keyword})
      when group not in [nil, [], [""]] and keyword in [nil, ""], do: group

  def get_category_groups(filter) do
    Category
    |> distinct([c], c.group)
    |> select([c], c.group)
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> Repo.all()
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

  defp with_type(query, group) when group in [nil, [], [""]], do: query

  defp with_type(query, group), do: where(query, [c], c.group in ^group)

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword), do: where(query, [c], ilike(c.name, ^"%#{keyword}%"))

  defp sort(query, sort_by),
    do: order_by(query, ^Map.get(@sort_options_map_for_query, sort_by, asc: :id))
end
