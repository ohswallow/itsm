defmodule ItsmWeb.PageController do
  use ItsmWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.

    user = conn.assigns[:current_user] || nil

    conn
    |> render(:home, layout: {ItsmWeb.Layouts, :default})
    |> Itsm.AccessLogger.maybe_log_access(nil, user, :home)
  end
end
