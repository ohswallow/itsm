defmodule Itsm.AuditLogger do
  alias Itsm.Repo
  alias Itsm.Logs.AuditLog

  def handle_event([:itsm, :repo, :query], measurements, metadata, _config) do
    query = metadata[:query]
    source = metadata[:source]

    is_success =
      case metadata[:result] do
        {:ok, _} -> true
        {:error, _} -> false
        _ -> false
      end

    action_type = extract_action(query)

    unless source in ["audit_logs", "access_logs"] or (action_type == "READ" and is_success) do
      action = if !is_success, do: "#{action_type}_FAILED", else: action_type

      params = %{
        table_name: source,
        target_id: metadata |> extract_id() |> ensure_string_id(),
        action: action,
        query_time_ms: Float.round(measurements.query_time / 1_000_000.0, 3),
        user_id: Process.get(:current_user_id)
      }

      Task.Supervisor.start_child(Itsm.TaskSupervisor, __MODULE__, :save_audit_log, [params])
    end
  end

  def save_audit_log(params) do
    %AuditLog{}
    |> AuditLog.changeset(params)
    |> Repo.insert()
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
end
