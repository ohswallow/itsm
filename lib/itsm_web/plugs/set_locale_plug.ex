defmodule ItsmWeb.Plugs.SetLocale do
  import Plug.Conn

  @supported_locales Gettext.known_locales(ItsmWeb.Gettext)

  def init(default), do: default

  def call(conn, _default) do
    locale = conn.params["locale"] || conn.cookies["locale"]
    locale = if locale in @supported_locales, do: locale, else: "ko"

    Gettext.put_locale(ItsmWeb.Gettext, locale)

    conn
    |> put_resp_cookie("locale", locale, max_age: 365 * 24 * 60 * 60)
    |> put_session(:locale, locale)
  end
end
