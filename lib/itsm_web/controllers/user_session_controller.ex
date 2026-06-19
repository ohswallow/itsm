defmodule ItsmWeb.UserSessionController do
  use ItsmWeb, :controller

  alias Itsm.Accounts
  alias ItsmWeb.UserAuth
  alias Itsm.AccessLogger

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_current_user_id()
      |> AccessLogger.maybe_log_access(nil, user, :login_success)
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> AccessLogger.maybe_log_access(nil, %{email: email}, :login_fail)
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_current_user_id()
    |> AccessLogger.maybe_log_access(nil, conn.assigns[:current_user], :log_out)
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp put_current_user_id(conn) do
    user_id =
      case conn.assigns do
        %{current_user: %{id: id}} -> id
        _ -> "user_session_controller"
      end

    unless Process.get(:current_user_id), do: Process.put(:current_user_id, user_id)
    conn
  end
end
