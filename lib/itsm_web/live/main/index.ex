defmodule ItsmWeb.MainLive.Index do
  use ItsmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Main")}
  end
end
