defmodule Itsm.AccessLogger do
  import Plug.Conn
  alias Itsm.Repo
  alias Itsm.Logs.AccessLog

  def maybe_log_access(conn, user, action) do
    if user do
      log_access(conn, user, action)
    end

    conn
  end

  def log_access(conn, user_or_data, action) do
    params = %{
      user_id: to_string(Map.get(user_or_data, :id) || Map.get(user_or_data, :email)),
      ip_address: extract_ip(conn),
      path: conn.request_path,
      action: to_string(action),
      metadata: %{
        user_agent: get_header(conn, "user-agent"),
        referer: get_header(conn, "referer"),
        accept_language: get_header(conn, "accept-language")
      }
    }

    Task.start(fn -> save_access_log(params) end)
  end

  def extract_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [addr | _] ->
        addr
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end

  def get_header(conn, header_name) do
    case get_req_header(conn, header_name) do
      [value | _] -> value
      [] -> nil
    end
  end

  def save_access_log(params) do
    %AccessLog{}
    |> AccessLog.changeset(params)
    |> Repo.insert()
  end
end
