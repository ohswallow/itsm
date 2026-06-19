defmodule ItsmWeb.Plugs.SetLocale do
  import Plug.Conn

  @supported_locales Gettext.known_locales(ItsmWeb.Gettext)

  def init(default), do: default

  def call(conn, _default) do
    # fetch_locale_from은 항상 유효한 로케일(또는 기본값 "ko")을 반환함
    locale = fetch_locale_from(conn)

    # 디버깅용
    IO.puts("Setting locale to: #{locale}")

    # 로케일 설정 로직 수행
    ItsmWeb.Gettext |> Gettext.put_locale(locale)

    conn
    |> put_resp_cookie("locale", locale, max_age: 365 * 24 * 60 * 60)
    |> put_session(:locale, locale)

    # case fetch_locale_from(conn) do
    #   nil ->
    #     # 디버깅용
    #     IO.puts("No locale found")
    #     conn

    #   locale ->
    #     # 디버깅용
    #     IO.puts("Setting locale to: #{locale}")
    #     ItsmWeb.Gettext |> Gettext.put_locale(locale)

    #     conn
    #     |> put_resp_cookie("locale", locale, max_age: 365 * 24 * 60 * 60)
    #     # LiveView를 위해 세션에도 저장
    #     |> put_session(:locale, locale)
    # end
  end

  defp fetch_locale_from(conn) do
    # (conn.params["locale"] || conn.cookies["locale"])
    # |> check_locale
    locale = conn.params["locale"] || conn.cookies["locale"]

    # locale이 없거나 유효하지 않으면 기본값 반환
    case check_locale(locale) do
      # 기본값을 명시적으로 설정
      nil -> "ko"
      valid_locale -> valid_locale
    end
  end

  defp check_locale(locale) when locale in @supported_locales, do: locale
  defp check_locale(_), do: nil
end
