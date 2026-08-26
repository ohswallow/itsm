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
        conn =
          conn
          |> Plug.Conn.fetch_session(conn)
          |> put_session("ex_saml_assertion_key", assertion_key)

        assertion = ExSaml.get_active_assertion(conn)
        saml_email = ExSaml.get_attribute(assertion, "email")
        [employee_number, _domain] = String.split(saml_email, "@", parts: 2)

        if user = Itsm.Accounts.get_user_by_employee_number(employee_number) do
          conn
          |> ItsmWeb.UserAuth.log_in_user(user)
          |> put_flash(:info, "로그인되었습니다.")
        else
          conn
          |> delete_session("ex_saml_assertion_key")
          |> put_flash(:error, "Invalid email")
          |> put_flash(:email, String.slice(saml_email, 0, 160))
          |> redirect(to: ~p"/")
        end

      nil ->
        conn
        |> put_flash(:error, "만료되었거나 유효하지 않은 인증 코드입니다.")
        |> redirect(to: ~p"/")
    end
  end
end
