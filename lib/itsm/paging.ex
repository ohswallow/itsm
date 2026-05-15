defmodule Itsm.Paging do
  import Ecto.Query
  alias Itsm.Repo
  alias Itsm.Utils

  def filter_by_range(query, params, opts \\ []) do
    range_columns = Keyword.get(opts, :range_columns, [])
    row_column = Map.get(params, "row_column")

    if is_list(range_columns) and range_columns != [] do
      target_params = ensure_row_column(params, row_column, range_columns)
      apply_range_filter(query, target_params, opts)
    else
      query
    end
  end

  def filter_status(query, search_columns, search, opts \\ [])

  def filter_status(query, _search_columns, search, _opts) when search in ["", nil],
    do: query

  def filter_status(query, search_columns, search, opts) do
    query_cond = Keyword.get(opts, :query_cond)
    {query_base, modules_map} = build_query_base(query, search_columns)

    dynamic_condition =
      Enum.reduce(search_columns, false, fn col_info, acc ->
        {b_name, field_name} = get_last_binding_and_field(col_info)
        module = Map.get(modules_map, b_name)

        if module do
          type = module.__schema__(:type, field_name)

          search_int =
            if is_binary(search) do
              case Integer.parse(search) do
                {num, _} -> num
                :error -> nil
              end
            else
              nil
            end

          cond do
            query_cond == :in ->
              search_list = search |> List.wrap()

              case type do
                t when t in [:string, :binary, :text] ->
                  dynamic([{^b_name, x}], field(x, ^field_name) in ^search_list or ^acc)

                t when t in [:integer, :id, :decimal] ->
                  ints =
                    Enum.map(search_list, &if(is_binary(&1), do: String.to_integer(&1), else: &1))

                  dynamic([{^b_name, x}], field(x, ^field_name) in ^ints or ^acc)

                _ ->
                  dynamic(
                    [{^b_name, x}],
                    type(field(x, ^field_name), :string) in ^search_list or ^acc
                  )
              end

            type in [:string, :binary] ->
              dynamic([{^b_name, x}], ilike(field(x, ^field_name), ^"%#{search}%") or ^acc)

            type in [:integer, :id, :decimal] and not is_nil(search_int) ->
              dynamic([{^b_name, x}], field(x, ^field_name) == ^search_int or ^acc)

            true ->
              dynamic(
                [{^b_name, x}],
                ilike(type(field(x, ^field_name), :string), ^"%#{search}%") or ^acc
              )
          end
        else
          acc
        end
      end)

    where(query_base, ^dynamic_condition)
  end

  @doc """
  ## Ecto 쿼리를 기반으로 검색, 페이징, 그리고 최적화된 프리로드를 수행합니다.

  - 이 함수는 `params`에서 페이지 번호와 검색어를 추출합니다.
  - 지정된 컬럼들에 대해 `ILIKE` 검색을 수행합니다.
  - 관계형 데이터(Association) 검색이 필요한 경우 자동으로 조인을 생성하며, 프리로드 시 필요한 필드만 가져오도록 최적화합니다.

  ### AND 조건
  - Post
  - |> Paging.filter_status(target_columns, con_val)  // 조건1
  - |> Paging.search_and_pagination(params, url, opts)  // 조건2
  - 위 파이프라인처럼 사용시 함수끼리 AND 조건 (조건1 AND 조건2)
  - 무조건 `search_and_pagination`를 마지막에 선언해야합니다.
  - `search_and_pagination`는 내부적으로 `filter_status`를 호출하여 사용
  - `search_and_pagination`의 인자값은 내부 `filter_status(opts[:default_columns], params["search"])` 값이 들어갑니다.

  ### 매개변수
  - `params`: LiveView의 `handle_params`나 컨트롤러에서 전달받은 파라미터 맵.
    - `"page"`: 현재 페이지 (기본값: 1)
    - `"page_size"`: 페이지당 항목 수 (기본값: 10)
    - `"search"`: 검색어 문자열 (기본값: "")
    - `"search_columns"`: 현재 선택된 검색 대상 컬럼 (기본값: `default_columns`)
    - `"range_column"`: 현재 선택된 날짜 범위 대상 컬럼 (없을시 날짜 선택 미노출)
    - `"start_date"`: 날짜 범위 대상 시작 조건 (기본값: `30일 전`)
    - `"end_date"`: 날짜 범위 대상 끝 조건 (기본값: `30일 후`)
  - `url`: 현재 페이지의 URL (결과 맵의 `current_path` 생성용).
  - `query_base`: 기본이 되는 Ecto 쿼리 또는 스키마 모듈 (예: `Post`).
  - `ops`: 나머지 옵션 값들
    - `default_columns`: 검색 가능하도록 허용할 컬럼 리스트.
      - 단순 컬럼: `[:title]`
      - 관계 컬럼: `[author: :display_name]` (자동으로 left_join 수행)
      - 중첩 관계: `[author: [profile: :nickname]]` (Profile까지 조인)
    - `preloads`: 결과 엔티티에 포함할 프리로드 설정.
      - 최적화 로직이 포함되어 있어 `{assoc, [:field1, :field2]}` 형태로 특정 필드만 지정 가능합니다.
    - `range_columns`: 날짜 범위 조건용 선택할 컬럼 리스트.
      - [:inserted_at, :updated_at]
    - `query_cond`: 쿼리 조건문을 선택하는 옵션입니다.(기본값: `ilike`, 선택 가능 값 `:in`)
    - `column_custom_label`: 검색 셀렉터에 표시 label을 바꿉니다. default_columns에 값을 key로 value를 원하는 라벨로 생성용
      - %{:title => "커스텀 제목", {:author, :display_name} => "작성자"}

  ### 반환 값
  `%{entries: list(), results: map()}` 형태의 맵을 반환합니다.
  - `entries`: 쿼리 결과 리스트 (스트림에 사용 가능).
  - `results`: 테이블 컨테이너 컴포넌트(`<.itsm_table_container results={assigns[:results]}>`)에서 요구하는 메타데이터 맵.

  """
  @spec search_and_pagination(
          query_base :: Ecto.Queryable.t(),
          params :: map(),
          url :: String.t(),
          opts :: [
            default_columns: [atom() | {atom(), atom() | tuple()} | list()],
            preloads: [atom() | {atom(), atom() | tuple() | list(atom())} | list(atom())],
            range_columns: [atom()],
            column_custom_label: map(),
            query_cond: atom()
          ]
        ) :: %{
          entries: [struct()],
          results: %{
            total_pages: integer(),
            total_count: integer(),
            columns_options: [{String.t(), String.t()}],
            current_path: String.t(),
            params: map(),
            range_column_options: [atom()]
          }
        }
  def search_and_pagination(query_base, params, url, opts \\ []) do
    default_columns = Keyword.get(opts, :default_columns, [:name])
    preloads = Keyword.get(opts, :preloads, [])
    range_columns = Keyword.get(opts, :range_columns, [])
    column_custom_label = Keyword.get(opts, :column_custom_label, %{})
    query_cond = Keyword.get(opts, :query_cond)

    page = parse_integer(params["page"], 1)
    page_size = parse_integer(params["page_size"], 10)
    search = params["search"] || ""
    offset_val = (page - 1) * page_size

    formatted_columns =
      if params["search_columns"] in [nil, [], [""], ""],
        do: [""],
        else:
          params["search_columns"]
          |> Enum.map(&flatten_value/1)

    formatted_range_column =
      if params["range_column"] in [nil, [], [""], ""],
        do: [""],
        else: flatten_value(params["range_column"])

    now = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC") |> DateTime.truncate(:second)

    start_date =
      if Utils.blank?(params["start_date"]),
        do: DateTime.add(now, -30, :day) |> DateTime.to_string(),
        else: params["start_date"]

    end_date =
      if Utils.blank?(params["end_date"]),
        do: DateTime.add(now, 30, :day) |> DateTime.to_string(),
        else: params["end_date"]

    search_columns = parse_columns(params["search_columns"], default_columns)

    query =
      query_base
      |> filter_status(search_columns, search, query_cond: query_cond)
      |> filter_by_range(params, opts)

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = if total_count == 0, do: 1, else: ceil(total_count / page_size)

    optimized_preloads = build_optimized_preloads(query_base, preloads)

    entries =
      query
      |> limit(^page_size)
      |> offset(^offset_val)
      |> preload(^optimized_preloads)
      |> Repo.all()

    results_params = %{
      page: page,
      page_size: page_size,
      search: search,
      search_columns: formatted_columns
    }

    range_params = %{
      range_column: formatted_range_column,
      start_date: start_date,
      end_date: end_date
    }

    results_params =
      if range_columns != [], do: Map.merge(results_params, range_params), else: results_params

    %{
      entries: entries,
      results: %{
        total_pages: total_pages,
        total_count: total_count,
        columns_options: build_options(default_columns, column_custom_label, :all),
        current_path: URI.parse(url).path,
        params: results_params,
        range_column_options: build_options(range_columns, column_custom_label)
      }
    }
  end

  defp ensure_row_column(params, val, range_columns) when val in [nil, "", [], [""]] do
    default_col = range_columns |> List.first() |> to_string()

    now = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC") |> DateTime.truncate(:second)
    start_date = params["start_date"] || DateTime.add(now, -30, :day) |> DateTime.to_string()
    end_date = params["end_date"] || DateTime.add(now, 30, :day) |> DateTime.to_string()

    params
    |> Map.put("row_column", default_col)
    |> Map.put_new("start_date", start_date)
    |> Map.put_new("end_date", end_date)
  end

  defp ensure_row_column(params, _val, _range_columns), do: params

  defp apply_range_filter(
         query,
         %{"row_column" => row_column, "start_date" => start_date, "end_date" => end_date},
         opts
       ) do
    range_columns = Keyword.get(opts, :range_columns, [])
    column = parse_columns(row_column, range_columns) |> List.first()

    s_dt = to_beginning_of_day(start_date)
    e_dt = to_end_of_day(end_date)

    {query_base, _module} = build_query_base(query, column)

    cond do
      s_dt && e_dt ->
        query_base |> where([q], field(q, ^column) >= ^s_dt and field(q, ^column) <= ^e_dt)

      s_dt ->
        query_base |> where([q], field(q, ^column) >= ^s_dt)

      e_dt ->
        query_base |> where([q], field(q, ^column) <= ^e_dt)

      true ->
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        past = DateTime.add(now, -30, :day)
        future = DateTime.add(now, 30, :day)

        query_base |> where([q], field(q, ^column) >= ^past and field(q, ^column) <= ^future)
    end
  end

  defp to_beginning_of_day(nil), do: nil
  defp to_beginning_of_day(""), do: nil

  defp to_beginning_of_day(val) do
    case to_date(val) do
      %Date{} = d -> DateTime.new!(d, ~T[00:00:00], "Etc/UTC")
      %DateTime{} = dt -> dt
      _ -> nil
    end
  end

  defp to_end_of_day(nil), do: nil
  defp to_end_of_day(""), do: nil

  defp to_end_of_day(val) do
    case to_date(val) do
      %Date{} = d ->
        DateTime.new!(d, ~T[23:59:59], "Etc/UTC") |> DateTime.add(1, :day)

      %DateTime{} = dt ->
        dt |> DateTime.add(1, :day)

      _ ->
        nil
    end
  end

  defp to_date(%DateTime{} = dt), do: dt
  defp to_date(%Date{} = d), do: d

  defp to_date(<<_YYYYMMdd::binary-size(10), "T", _rest::binary>> = str) do
    str |> DateTime.from_iso8601() |> elem(1)
  end

  defp to_date(
         <<_year::binary-size(4), "-", _month::binary-size(2), "-", _day::binary-size(2)>> = str
       ) do
    str |> Date.from_iso8601() |> elem(1)
  end

  defp to_date(_), do: nil

  defp build_query_base(query_base, search_columns) do
    initial_state =
      case query_base do
        module when is_atom(module) ->
          {from(m in module, as: :main), %{main: module}}

        query ->
          query
      end

    search_columns
    |> List.wrap()
    |> Enum.reduce(initial_state, fn
      {modules, _col}, %Ecto.Query{from: %{source: {_, module}}} = acc ->
        ensure_join(acc, modules, {module, modules})

      col, {query, modules} ->
        ensure_join(query, modules, col)

      col, %Ecto.Query{from: %{source: {_, module}}} = acc ->
        ensure_join(acc, %{acc.from.as => module}, col)

      _col, acc ->
        acc
    end)
  end

  defp build_options(default_columns, column_custom_label, opt \\ :none)

  defp build_options(default_columns, nil, :all) do
    [{"전체", ""}] ++
      Enum.map(default_columns, fn col -> {flatten_label(col), flatten_value(col)} end)
  end

  defp build_options(default_columns, nil, :none) do
    Enum.map(default_columns, fn col -> {flatten_label(col), flatten_value(col)} end)
  end

  defp build_options(default_columns, column_custom_label, opt)
       when is_map(column_custom_label) do
    custom_label_columns = Enum.filter(default_columns, &Map.has_key?(column_custom_label, &1))
    remaining_columns = default_columns -- custom_label_columns

    build_options(remaining_columns, nil, opt) ++
      Enum.map(custom_label_columns, &{Map.get(column_custom_label, &1), flatten_value(&1)})
  end

  defp parse_columns(columns, default_columns) when columns not in [nil, "", [], [""]] do
    allowed_fields =
      default_columns
      |> Enum.map(&flatten_value(&1))

    columns
    |> List.wrap()
    |> Enum.reject(&(&1 in ["", nil]))
    |> Enum.map(&(&1 |> String.replace(" ", "_") |> String.downcase()))
    |> Enum.filter(&(&1 in allowed_fields))
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

  defp parse_columns(_columns, default_columns), do: default_columns

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

      _field ->
        {query, modules}
    end
  end

  defp do_ensure_join(query, modules, parent_name, assoc_name) do
    if Map.has_key?(modules, assoc_name) do
      {query, modules}
    else
      parent_mod = Map.get(modules, parent_name)

      if assoc_name in parent_mod.__schema__(:associations) do
        if has_named_binding?(query, assoc_name) do
          %{related: child_mod} = parent_mod.__schema__(:association, assoc_name)
          {query, Map.put(modules, assoc_name, child_mod)}
        else
          %{related: child_mod} = parent_mod.__schema__(:association, assoc_name)

          new_query =
            join(query, :left, [{^parent_name, p}], a in assoc(p, ^assoc_name), as: ^assoc_name)

          {new_query, Map.put(modules, assoc_name, child_mod)}
        end
      else
        {query, modules}
      end
    end
  end

  defp build_optimized_preloads(%Ecto.Query{from: %{source: {_, module}}}, preloads) do
    do_build_optimized_preloads(module, preloads)
  end

  defp build_optimized_preloads(schema, preloads) do
    do_build_optimized_preloads(schema, preloads)
  end

  defp do_build_optimized_preloads(schema, preloads) do
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
  defp flatten_value(col) when is_binary(col), do: col
  defp flatten_value(col), do: col

  defp flatten_label([head | _tail]), do: flatten_label(head)

  defp flatten_label({binding, rest}) do
    case {translate_label(binding), flatten_label(rest)} do
      {"", r} -> r
      {b, ""} -> b
      {b, r} -> "#{b}.#{r}"
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
