defmodule Itsm.Graphql.Macros do
  import Absinthe.Schema.Notation, only: [arg: 2, arg: 3, list_of: 1, meta: 2]

  defmacro paginated_object(name, type) do
    quote do
      object unquote(name) do
        field :entries, list_of(unquote(type))
        field :results, :paging_results
      end
    end
  end

  defmacro pagination_args(search_columns, range_columns) do
    docs_search_str = "`#{stringify_ast(search_columns)}`"
    docs_range_str = "`#{stringify_ast(range_columns)}`"

    quote do
      arg(:page, :integer, default_value: 1)
      arg(:page_size, :integer, default_value: 10)
      arg(:search, :string)
      arg(:start_date, :string)
      arg(:end_date, :string)

      arg(:range_column, :string, description: "검색가능 컬럼: #{unquote(docs_range_str)}")

      arg(:search_columns, list_of(:string),
        description: "컬럼들은 or 조건\n검색가능 컬럼: #{unquote(docs_search_str)}"
      )

      meta(:default_columns, unquote(search_columns))
      meta(:range_columns, unquote(range_columns))
    end
  end

  defp stringify_ast(ast) do
    ast
    |> Macro.prewalk([], fn
      atom, acc when is_atom(atom) and not is_nil(atom) ->
        {atom, [Atom.to_string(atom) | acc]}

      {key, value}, acc when is_atom(key) ->
        prefix = Atom.to_string(key)
        flat_fields = flatten_nested(value)
        strings = Enum.map(flat_fields, &"#{prefix}.#{&1}")
        {{key, value}, strings ++ acc}

      other, acc ->
        {other, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
    |> inspect()
  end

  defp flatten_nested(atom) when is_atom(atom), do: [Atom.to_string(atom)]

  defp flatten_nested(list) when is_list(list) do
    Enum.flat_map(list, fn
      {k, v} -> Enum.map(flatten_nested(v), &"#{Atom.to_string(k)}.#{&1}")
      atom -> [Atom.to_string(atom)]
    end)
  end
end
