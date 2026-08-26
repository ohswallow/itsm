defmodule Itsm.Accounts.UserNotifier do
  alias Itsm.Workb

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    %Workb{
      recipient: user.employee_number,
      title: "#{Gettext.gettext(ItsmWeb.Gettext, "ITSM Login Magic Link")}",
      body: """
      #{Gettext.gettext(ItsmWeb.Gettext, "Hi")} #{user.display_name},

      #{Gettext.gettext(ItsmWeb.Gettext, "You can log into your account by visiting the URL below")}:

      <a href="#{url}" target="_blank">#{Gettext.gettext(ItsmWeb.Gettext, "ITSM Login")}</a>
      """
    }
    |> Workb.send_message()
  end
end
