defmodule ItsmWeb.PageController do
  use ItsmWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
