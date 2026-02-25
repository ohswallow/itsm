defmodule Itsm.Categories do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Category

  @sort_options_list [
    %{label: "이름 오름차순", value: "name_asc", order: [asc: :name]},
    %{label: "이름 내림차순", value: "name_desc", order: [desc: :name]}
  ]

  @sort_options_map_for_query Map.new(@sort_options_list, fn opt -> {opt.value, opt.order} end)

  def sort_options, do: Enum.map(@sort_options_list, &{&1.label, &1.value})

  def filter_categories(filter) do
    Category
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> where([c], c.active == true)
    |> sort(filter["sort_by"])
    |> Repo.all()
  end

  def get_category_groups(%{"group" => group, "keyword" => keyword})
      when group not in [nil, [], [""]] and keyword in [nil, ""],
      do: group

  def get_category_groups(filter) do
    Category
    |> distinct([c], c.group)
    |> select([c], c.group)
    |> with_type(filter["group"])
    |> search_by(filter["keyword"])
    |> where([c], c.active == true)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(Category, id)

  defp with_type(query, group) when group in [nil, [], [""]], do: query

  defp with_type(query, group), do: where(query, [c], c.group in ^group)

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword), do: where(query, [c], ilike(c.name, ^"%#{keyword}%"))

  defp sort(query, sort_by),
    do: order_by(query, ^Map.get(@sort_options_map_for_query, sort_by, asc: :id))
end
