defmodule ItsmWeb.PageController do
  use ItsmWeb, :controller

  def home(conn, %{"code" => code}) do
    handle_saml_callback(conn, code)
  end

  def home(conn, _params) do
    if get_session(conn, "ex_saml_assertion_key") do
      redirect(conn, to: ~p"/main")
    else
      render(conn, :home)
    end
  end

  defp handle_saml_callback(conn, code) do
    case ExSaml.AuthorizationCodeCache.take(code) do
      %{ex_saml_assertion_key: assertion_key, saml_nonce_candidate: _nonce} ->
        conn = put_session(conn, "ex_saml_assertion_key", assertion_key)

        conn = Plug.Conn.fetch_session(conn)

        assertion = ExSaml.get_active_assertion(conn)
        saml_email = ExSaml.get_attribute(assertion, "email")

        [email_id, _domain] = String.split(saml_email, "@", parts: 2)

        email = "#{email_id}@sample.com"

        if user = Itsm.Accounts.get_user_by_email(email) do
          conn
          |> ItsmWeb.UserAuth.log_in_user(user)
          |> put_flash(:info, "성공적으로 로그인되었습니다.")
        else
          conn
          |> put_flash(:error, "Invalid email")
          |> put_flash(:email, String.slice(email, 0, 160))
          |> redirect(to: ~p"/users/log-in")
        end

      nil ->
        conn
        |> put_flash(:error, "만료되었거나 유효하지 않은 인증 코드입니다.")
        |> redirect(to: ~p"/")
    end
  end
end
