defmodule Itsm.Paging do
  import Ecto.Query
  alias Itsm.Repo

  def search_and_pagination(params, url, query_base, default_columns \\ [:name], preloads \\ []) do
    page = parse_integer(params["page"], 1)
    page_size = parse_integer(params["page_size"], 10)
    search = params["search"] || ""
    offset_val = (page - 1) * page_size

    search_columns =
      if params["search_columns"] in [nil, "", [], [""]],
        do: default_columns,
        else: parse_columns(params["search_columns"])

    joined_query = build_query_base(query_base, search_columns)

    query =
      if search != "" do
        from p in joined_query,
          where:
            ^Enum.reduce(search_columns, false, fn col_info, acc ->
              {b_name, field_name} = get_last_binding_and_field(col_info)

              case b_name do
                :main ->
                  dynamic([p], ilike(field(p, ^field_name), ^"%#{search}%") or ^acc)

                _ ->
                  dynamic([{^b_name, b}], ilike(field(b, ^field_name), ^"%#{search}%") or ^acc)
              end
            end)
      else
        joined_query
      end

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = if total_count == 0, do: 1, else: ceil(total_count / page_size)

    entries =
      query
      |> limit(^page_size)
      |> offset(^offset_val)
      |> preload(^preloads)
      |> Repo.all()

    formatted_columns =
      if params["search_columns"] in [nil, [], [""], ""],
        do: [""],
        else:
          search_columns
          |> Enum.map(&flatten_value/1)
          |> then(fn
            [] -> [""]
            list -> list
          end)

    params = %{
      page: page,
      page_size: page_size,
      search: search,
      search_columns: formatted_columns
    }

    %{
      entries: entries,
      total_pages: total_pages,
      total_count: total_count,
      columns_options: build_options(default_columns),
      current_path: URI.parse(url).path,
      params: params
    }
  end

  def build_query_base(query_base, search_columns) do
    search_columns
    |> List.wrap()
    |> Enum.reduce(query_base, fn
      col_info, query when is_tuple(col_info) ->
        ensure_join(query, col_info)

      _col, query ->
        query
    end)
  end

  def build_options(default_columns) do
    [{"전체", ""}] ++
      Enum.map(default_columns, fn col ->
        {flatten_label(col), flatten_value(col)}
      end)
  end

  def parse_columns(columns) do
    columns
    |> List.wrap()
    |> Enum.reject(&(&1 in ["", nil]))
    |> Enum.map(fn
      col_str when is_binary(col_str) ->
        col_str
        |> String.split(".")
        |> Enum.map(&String.to_existing_atom/1)
        |> nest_atoms()

      col ->
        col
    end)
  end

  defp parse_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {num, _} -> num
      :error -> default
    end
  end

  defp parse_integer(nil, default), do: default
  defp parse_integer(value, _default) when is_integer(value), do: value

  defp get_last_binding_and_field({_parent, child}) when is_tuple(child) do
    get_last_binding_and_field(child)
  end

  defp get_last_binding_and_field({parent, field}) when is_atom(field) do
    {parent, field}
  end

  defp get_last_binding_and_field(field) when is_atom(field) do
    {:main, field}
  end

  defp ensure_join(query, assoc_name) when is_atom(assoc_name) do
    if has_named_binding?(query, assoc_name) do
      query
    else
      join(query, :left, [p], a in assoc(p, ^assoc_name), as: ^assoc_name)
    end
  end

  defp ensure_join(query, {parent, child}) do
    query = ensure_join(query, parent)

    case child do
      {child_assoc, next_step} ->
        query =
          if has_named_binding?(query, child_assoc) do
            query
          else
            join(query, :left, [{^parent, p}], c in assoc(p, ^child_assoc), as: ^child_assoc)
          end

        ensure_join(query, {child_assoc, next_step})

      field when is_atom(field) ->
        query
    end
  end

  defp flatten_value(col) when col in ["", nil, [], [""]], do: [""]
  defp flatten_value({binding, rest}), do: "#{binding}.#{flatten_value(rest)}"
  defp flatten_value(col) when is_atom(col), do: Atom.to_string(col)

  defp flatten_label({binding, rest}) do
    case {translate_label(binding), flatten_label(rest)} do
      {"", r} -> r
      {b, ""} -> b
      {b, r} -> "#{b} #{r}"
    end
  end

  defp flatten_label(col), do: translate_label(col)

  defp translate_label(atom) when is_atom(atom) do
    label = atom |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
    Gettext.gettext(ItsmWeb.Gettext, label)
  end

  defp translate_label(string) when is_binary(string) do
    label = String.capitalize(string)
    Gettext.gettext(ItsmWeb.Gettext, label)
  end

  defp translate_label(_), do: ""

  defp nest_atoms([last]), do: last
  defp nest_atoms([head | tail]), do: {head, nest_atoms(tail)}
end
