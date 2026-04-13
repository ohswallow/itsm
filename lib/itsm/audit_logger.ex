defmodule Itsm.AuditLogger do
  alias Itsm.Repo
  alias Itsm.Logs.AuditLog

  def handle_event([:itsm, :repo, :query], measurements, metadata, _config) do
    query = metadata.query
    source = metadata[:source]

    unless source in ["audit_logs", "access_logs"] do
      cond do
        String.starts_with?(query, ["INSERT", "UPDATE", "DELETE"]) ->
          query_time_ms = measurements.query_time / 1_000_000.0
          rounded_time = Float.round(query_time_ms, 3)
          cleaned_params = sanitize_params(metadata.params)

          full_query = query |> interpolate_query(cleaned_params)

          params = %{
            table_name: source,
            target_id: metadata |> extract_id() |> ensure_string_id(),
            action: extract_action(query),
            target: full_query,
            result: %{params: cleaned_params},
            query_time_ms: rounded_time,
            user_id: Process.get(:current_user_id)
          }

          Task.start(fn -> save_audit_log(params) end)

        true ->
          :ok
      end
    end
  end

  defp sanitize_params(params) when is_list(params) do
    Enum.map(params, fn
      val when is_binary(val) and byte_size(val) == 16 ->
        Ecto.UUID.cast!(val)

      val when is_binary(val) ->
        if String.printable?(val) do
          val
        else
          "base64:" <> Base.encode64(val)
        end

      val when is_struct(val, DateTime) or is_struct(val, NaiveDateTime) ->
        DateTime.to_iso8601(val)

      val ->
        val
    end)
  end

  defp interpolate_query(query, params) do
    params
    |> Enum.with_index(1)
    |> Enum.sort_by(fn {_, index} -> index end, :desc)
    |> Enum.reduce(query, fn {val, index}, acc ->
      formatted_val =
        case val do
          v when is_binary(v) ->
            "'#{v}'"

          %DateTime{} = v ->
            "'#{DateTime.to_iso8601(v)}'"

          v when is_map(v) or is_list(v) ->
            "'#{String.replace(inspect(v), "'", "''")}'"

          v ->
            "#{v}"
        end

      String.replace(acc, "$#{index}", formatted_val)
    end)
    |> String.replace("\\\"", "\"")
    |> String.replace(~r/,(?!\s)/, ", ")
  end

  defp extract_id(metadata) do
    params = metadata[:params] || []

    get_id_from_rows(metadata) ||
      find_last_uuid(params) ||
      find_any_uuid(params) ||
      "N/A"
  end

  defp get_id_from_rows(metadata) do
    case metadata[:result] do
      {:ok, %{rows: [row_values]}} when is_list(row_values) ->
        id_index = Enum.find_index(metadata[:columns] || [], &(&1 == "id"))

        if id_index, do: Enum.at(row_values, id_index), else: nil

      _ ->
        nil
    end
  end

  defp find_last_uuid(params) do
    last = List.last(params)
    if is_uuid?(last), do: Ecto.UUID.cast!(last), else: nil
  end

  defp find_any_uuid(params) do
    params
    |> Enum.reverse()
    |> Enum.find(&is_uuid?/1)
    |> then(fn
      nil -> nil
      val -> Ecto.UUID.cast!(val)
    end)
  end

  defp is_uuid?(val), do: is_binary(val) and byte_size(val) == 16

  defp ensure_string_id(nil), do: nil
  defp ensure_string_id(id) when is_binary(id) and byte_size(id) == 16, do: Ecto.UUID.load!(id)
  defp ensure_string_id(id) when is_binary(id), do: id
  defp ensure_string_id(id), do: to_string(id)

  defp extract_action(query) do
    case query |> String.trim() |> String.upcase() do
      "INSERT" <> _ -> "CREATE"
      "SELECT" <> _ -> "READ"
      "UPDATE" <> _ -> "UPDATE"
      "DELETE" <> _ -> "DELETE"
      _ -> "UNKNOWN"
    end
  end

  defp save_audit_log(params) do
    %AuditLog{}
    |> AuditLog.changeset(params)
    |> Repo.insert()
  end
end
