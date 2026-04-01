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

    {joined_query, modules_map} = build_query_base(query_base, search_columns)

    query =
      if search != "" do
        from p in joined_query,
          where:
            ^Enum.reduce(search_columns, false, fn col_info, acc ->
              {b_name, field_name} = get_last_binding_and_field(col_info)
              module = Map.get(modules_map, b_name)

              if module do
                type = module.__schema__(:type, field_name)
                search_pattern = "%#{search}%"

                search_int =
                  case Integer.parse(search) do
                    {num, _} -> num
                    :error -> nil
                  end

                cond do
                  type in [:string, :binary] ->
                    dynamic([{^b_name, x}], ilike(field(x, ^field_name), ^search_pattern) or ^acc)

                  type in [:integer, :id, :decimal] and not is_nil(search_int) ->
                    dynamic([{^b_name, x}], field(x, ^field_name) == ^search_int or ^acc)

                  true ->
                    dynamic(
                      [{^b_name, x}],
                      ilike(type(field(x, ^field_name), :string), ^search_pattern) or ^acc
                    )
                end
              else
                acc
              end
            end)
      else
        joined_query
      end

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = if total_count == 0, do: 1, else: ceil(total_count / page_size)

    optimized_preloads = build_optimized_preloads(query_base, preloads)

    entries =
      query
      |> limit(^page_size)
      |> offset(^offset_val)
      |> preload(^optimized_preloads)
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
      results: %{
        total_pages: total_pages,
        total_count: total_count,
        columns_options: build_options(default_columns),
        current_path: URI.parse(url).path,
        params: params
      }
    }
  end

  defp build_query_base(query_base, search_columns) do
    initial_state = {from(m in query_base, as: :main), %{main: query_base}}

    search_columns
    |> List.wrap()
    |> Enum.reduce(initial_state, fn
      col_info, {query, modules} when is_tuple(col_info) ->
        ensure_join(query, modules, col_info)

      _col, acc ->
        acc
    end)
  end

  defp build_options(default_columns) do
    [{"전체", ""}] ++
      Enum.map(default_columns, fn col ->
        {flatten_label(col), flatten_value(col)}
      end)
  end

  defp parse_columns(columns) do
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

  defp ensure_join(query, modules, assoc_name) when is_atom(assoc_name) do
    do_ensure_join(query, modules, :main, assoc_name)
  end

  defp ensure_join(query, modules, {parent, child}) do
    {query, modules} = ensure_join(query, modules, parent)

    case child do
      {child_assoc, next_step} ->
        {query, modules} = do_ensure_join(query, modules, parent, child_assoc)
        ensure_join(query, modules, {child_assoc, next_step})

      field when is_atom(field) ->
        {query, modules}
    end
  end

  defp do_ensure_join(query, modules, parent_name, assoc_name) do
    if has_named_binding?(query, assoc_name) do
      {query, modules}
    else
      parent_mod = Map.fetch!(modules, parent_name)
      %{related: child_mod} = parent_mod.__schema__(:association, assoc_name)

      new_query =
        join(query, :left, [{^parent_name, p}], a in assoc(p, ^assoc_name), as: ^assoc_name)

      new_modules = Map.put(modules, assoc_name, child_mod)

      {new_query, new_modules}
    end
  end

  defp build_optimized_preloads(schema, preloads) do
    Enum.map(preloads, fn
      assoc when is_atom(assoc) ->
        assoc

      {assoc, content} ->
        target_schema = schema.__schema__(:association, assoc).queryable
        {nested_preloads, fields} = Enum.split_with(List.wrap(content), &is_tuple/1)
        optimized_nested = build_optimized_preloads(target_schema, nested_preloads)
        required_keys = get_required_keys(nested_preloads, target_schema)
        final_fields = Enum.uniq(required_keys ++ fields)

        query = from(s in target_schema, select: ^final_fields)
        query = if optimized_nested == [], do: query, else: preload(query, ^optimized_nested)

        {assoc, query}
    end)
  end

  defp get_required_keys(nested_preloads, target_schema) do
    [
      :id
      | Enum.map(nested_preloads, &target_schema.__schema__(:association, elem(&1, 0)).owner_key)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp flatten_value([head | _tail]), do: flatten_value(head)
  defp flatten_value(col) when col in ["", nil, [], [""]], do: [""]
  defp flatten_value({binding, rest}), do: "#{binding}.#{flatten_value(rest)}"
  defp flatten_value(col) when is_atom(col), do: Atom.to_string(col)

  defp flatten_label([head | _tail]), do: flatten_label(head)

  defp flatten_label({binding, rest}) do
    case {translate_label(binding), flatten_label(rest)} do
      {"", r} -> r
      {b, ""} -> b
      {b, r} -> "#{b} #{r}"
    end
  end

  defp flatten_label(col), do: translate_label(col)

  defp translate_label(atom) when is_atom(atom) do
    label =
      atom |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)

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
