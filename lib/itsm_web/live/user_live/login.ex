defmodule ItsmWeb.UserLive.Login do
  use ItsmWeb, :live_view

  alias Itsm.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>{gettext("Log in")}</p>
          </.header>
        </div>
        
        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:employee_number]}
            label={gettext("Employee Number")}
            autocomplete="username"
            spellcheck="false"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            {gettext("Log in with employee number")} <span aria-hidden="true">→</span>
          </.button>
        </.form>
        
        <div class="divider">{gettext("or")}</div>
        
        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:employee_number]}
            label="Employee Number"
            autocomplete="username"
            spellcheck="false"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
            spellcheck="false"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            {gettext("Log in and stay logged in")} <span aria-hidden="true">→</span>
          </.button>
          
          <.button class="btn btn-primary btn-soft w-full mt-2">
            {gettext("Log in only this time")}
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    current_user =
      if session["user_token"], do: Accounts.get_user_by_session_token(session["user_token"])

    case current_user do
      {%Itsm.Accounts.User{}, _} ->
        {:ok, redirect(socket, to: "/main")}

      _ ->
        employee_number = Phoenix.Flash.get(socket.assigns.flash, :employee_number)
        form = to_form(%{"employee_number" => employee_number}, as: "user")
        {:ok, assign(socket, form: form, trigger_submit: false)}
    end
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"employee_number" => employee_number}}, socket) do
    if user = Accounts.get_user_by_employee_number(employee_number) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      Gettext.gettext(
        ItsmWeb.Gettext,
        "Sent a magic link to Workb for ITSM login. Please check the Workb messages."
      )

    {:noreply,
     socket
     |> put_flash(:employee_number, employee_number)
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
