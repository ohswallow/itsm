defmodule Itsm.AccessLogger do
  alias Itsm.Repo
  alias Itsm.Logs.AccessLog

  def maybe_log_access(conn_or_socket, session, user, action) do
    access_log = log_access(conn_or_socket, session, get_log_subject(user), action)
    save_use_supervisor(conn_or_socket, access_log)
  end

  def log_access(conn_or_socket, session, user_or_data, action) do
    %{
      user_id: extract_user_id(user_or_data),
      ip_address: extract_ip(conn_or_socket),
      path: extract_path(conn_or_socket),
      action: to_string(action),
      metadata: extract_metadata(conn_or_socket, session)
    }
  end

  def save_use_supervisor(socket, access_log) do
    Task.Supervisor.start_child(
      Itsm.TaskSupervisor,
      __MODULE__,
      :save_access_log,
      [Map.put(access_log, :path, access_log[:path] || socket.assigns[:path] || "/")]
    )

    socket
  end

  def save_use_supervisor(socket) do
    Task.Supervisor.start_child(
      Itsm.TaskSupervisor,
      __MODULE__,
      :save_access_log,
      [Map.put(socket.assigns[:access_log] || %{}, :path, socket.assigns[:path] || "/")]
    )

    socket
  end

  def save_access_log(params) do
    %AccessLog{}
    |> AccessLog.changeset(params)
    |> Repo.insert()
  end

  defp extract_ip(source) do
    case get_header(source, "x-forwarded-for") do
      nil ->
        get_peer_address(source)

      addr ->
        addr |> String.split(",") |> List.first() |> String.trim()
    end
  end

  defp get_peer_address(%Plug.Conn{} = conn), do: conn.remote_ip |> :inet.ntoa() |> to_string()

  defp get_peer_address(%Phoenix.LiveView.Socket{} = socket) do
    case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
      %{address: addr} -> addr |> :inet.ntoa() |> to_string()
      _ -> "unknown"
    end
  end

  defp extract_path(%Plug.Conn{} = conn), do: conn.request_path || "/"

  defp extract_path(%Phoenix.LiveView.Socket{} = socket) do
    socket.assigns[:path] || "/"
  end

  defp extract_metadata(%Plug.Conn{} = conn, _session) do
    [live_socket_name, live_socket_id] =
      split_socket_id(Plug.Conn.get_session(conn, :live_socket_id))

    %{
      user_agent: get_header(conn, "user-agent") |> summarize_ua(),
      view_name: conn.private[:phoenix_view],
      live_socket_id: live_socket_id,
      live_socket_name: live_socket_name,
      live_action: conn.private[:phoenix_live_action],
      referer: get_header(conn, "referer")
    }
  end

  defp extract_metadata(%Phoenix.LiveView.Socket{} = socket, session) do
    [live_socket_name, live_socket_id] = split_socket_id(session["live_socket_id"])

    %{
      user_agent: get_header(socket, "user-agent") |> summarize_ua(),
      view_name: socket.view |> Module.split() |> Enum.at(-2),
      live_socket_id: live_socket_id,
      live_socket_name: live_socket_name,
      live_action: socket.assigns[:live_action],
      referer: get_header(socket, "referer")
    }
  end

  defp extract_user_id(nil), do: "anonymous_guest"
  defp extract_user_id(user) when is_map(user), do: user.id || user[:email]
  defp extract_user_id(user), do: to_string(user)

  defp get_header(%Plug.Conn{} = conn, header_name) do
    case Plug.Conn.get_req_header(conn, header_name) do
      [value | _] -> value
      [] -> nil
    end
  end

  defp get_header(%Phoenix.LiveView.Socket{} = socket, "user-agent"),
    do: Phoenix.LiveView.get_connect_info(socket, :user_agent)

  defp get_header(%Phoenix.LiveView.Socket{} = socket, "x-forwarded-for") do
    headers = Phoenix.LiveView.get_connect_info(socket, :x_headers) || []
    Enum.find_value(headers, fn {k, v} -> if k == "x-forwarded-for", do: v end)
  end

  defp get_header(%Phoenix.LiveView.Socket{} = socket, header_name) do
    if Phoenix.LiveView.connected?(socket) do
      headers = Phoenix.LiveView.get_connect_info(socket, :x_headers) || []

      case List.keyfind(headers, String.downcase(header_name), 0) do
        {k, v} when k == header_name -> v
        _ -> nil
      end
    else
      nil
    end
  end

  defp get_header(_, _), do: nil

  defp split_socket_id(nil), do: ["unknown", "unknown"]

  defp split_socket_id(id) do
    case String.split(id, ":", parts: 2) do
      [name, id] -> [name, id]
      _ -> ["unknown", "unknown"]
    end
  end

  defp get_log_subject(nil), do: "anonymous_guest"
  defp get_log_subject(user), do: user

  defp summarize_ua(ua) when is_binary(ua) do
    os =
      cond do
        String.contains?(ua, "Windows") -> "Windows"
        String.contains?(ua, "Macintosh") -> "macOS"
        String.contains?(ua, "iPhone") -> "iOS"
        String.contains?(ua, "Android") -> "Android"
        true -> "Unknown OS"
      end

    browser =
      cond do
        String.contains?(ua, "Edg/") -> "Edge"
        String.contains?(ua, "Chrome/") -> "Chrome"
        String.contains?(ua, "Safari/") -> "Safari"
        String.contains?(ua, "Firefox/") -> "Firefox"
        true -> "Unknown Browser"
      end

    "#{os} / #{browser}"
  end

  defp summarize_ua(_), do: "Unknown"
end
