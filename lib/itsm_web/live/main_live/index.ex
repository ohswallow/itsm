defmodule ItsmWeb.MainLive.Index do
  use ItsmWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Main") |> assign(:app_env, System.get_env("APP_NAME"))}
  end
end
