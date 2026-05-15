defmodule ItsmWeb.UserRegistrationLive do
  use ItsmWeb, :live_view

  alias Itsm.Accounts
  alias Itsm.Accounts.User
  alias Itsm.CommonCodes

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <.input field={@form[:employee_number]} type="text" label="직원번호" required />
        <.input field={@form[:display_name]} type="text" label="직원명" required />
        <.input
          field={@form[:organization_code]}
          type="select"
          label={gettext("Organization")}
          prompt="Choose a value"
          options={@organization_options}
        />
        <.input
          field={@form[:department_code]}
          type="select"
          label={gettext("Department")}
          prompt="Choose a value"
          options={@department_options}
        />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
      |> assign_new_options()

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(fill_org_dept_codes(user_params)) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:organization_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:department_options, fn -> CommonCodes.get_select_options("부서") end)
  end

  defp fill_org_dept_codes(attrs) do
    org_code = attrs["organization_code"]
    org_name = CommonCodes.get_label("계열사", org_code)
    dept_code = attrs["department_code"]
    dept_name = CommonCodes.get_label("부서", dept_code)

    attrs
    |> Map.put("department", dept_name)
    |> Map.put("organization", org_name)
  end
end
