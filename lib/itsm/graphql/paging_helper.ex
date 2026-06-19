defmodule Itsm.Graphql.PagingHelper do
  @moduledoc """
  Absinthe GraphQL 요청을 Itsm.Paging 모듈과 연결해주는 브릿지 모듈.
  """
  alias Itsm.Paging

  def paginate(query_base, args, resolution, opts \\ []) do
    string_params = stringify_keys(args)

    entries_node =
      Absinthe.Resolution.project(resolution)
      |> Enum.find(&(&1.schema_node.identifier == :entries))

    entries_ast =
      if entries_node, do: parse_resolution_fields(entries_node.selections), else: []

    {dynamic_preloads, _top_fields} =
      Enum.split_with(entries_ast, fn
        {_key, _value} -> true
        _ -> false
      end)

    final_preloads = Keyword.get(opts, :preloads, []) ++ dynamic_preloads
    opts = Keyword.put(opts, :preloads, final_preloads)

    result = Paging.search_and_pagination(query_base, string_params, "/graphql", opts)

    {:ok, result}
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {:search_columns, v} ->
        {"search_columns", v}

      {:range_column, v} ->
        {"row_column", v}

      {:start_date, v} ->
        {"start_date", v}

      {:end_date, v} ->
        {"end_date", v}

      {k, v} when is_atom(k) ->
        {Atom.to_string(k), stringify_keys(v)}

      {k, v} ->
        {k, v}
    end)
  end

  defp stringify_keys(value), do: value

  defp parse_resolution_fields(projections) do
    Enum.map(projections, fn proj ->
      identifier = proj.schema_node.identifier

      case proj.selections do
        [] ->
          identifier

        sub_projections ->
          {identifier, parse_resolution_fields(sub_projections)}
      end
    end)
  end
end
