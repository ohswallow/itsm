defmodule ItsmWeb.Admin.LoginForceController do
  use ItsmWeb, :controller

  def force(conn, %{"employee_number" => employee_number}) do
    user = Itsm.Accounts.get_user_by_employee_number(employee_number)

    conn |> ItsmWeb.UserAuth.log_in_user(user)
  end
end
