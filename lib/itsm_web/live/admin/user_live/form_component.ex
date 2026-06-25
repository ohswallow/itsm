defmodule ItsmWeb.Admin.UserLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Accounts
  alias Itsm.Admin.CommonCodes

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:conflict, fn -> false end)
     |> assign_new(:conflict_msg, fn -> nil end)
     |> assign_new(:form, fn -> to_form(Accounts.change_user(user)) end)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.card
        visible={@conflict}
        state={:error}
        title="⚠️ 충돌 발생!"
      >
        <p>{@conflict_msg}</p>
        <p>현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </.card>

      <.form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="text" label={gettext("Email")} />
        <.input
          :if={@action == :new}
          field={@form[:password]}
          type="text"
          label={gettext("Password")}
        />
        <.itsm_calendar
          field={@form[:confirmed_at]}
          label={gettext("Confirmed At")}
          show_time
          default_selected_date_time={@form[:confirmed_at].value}
        /> <.input field={@form[:employee_number]} type="text" label={gettext("Employee Number")} />
        <.input field={@form[:display_name]} type="text" label={gettext("Display Name")} />
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
        /> <.input field={@form[:role]} type="text" label={gettext("Role")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />

        <.button :if={!@conflict} phx-disable-with="Saving...">Save User</.button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, fill_org_dept_codes(user_params))
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:organization_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:department_options, fn -> CommonCodes.get_select_options("부서") end)
  end

  defp save_user(socket, :edit, user_params) do
    %{current_scope: %{user: action_user}, user: user} = socket.assigns

    case Accounts.update_user(action_user, user, user_params) do
      {:ok, user} ->
        socket =
          if action_user.id == user.id, do: socket |> assign(:current_user, user), else: socket

        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Accounts.create_user(action_user, user_params) do
      {:ok, user} ->
        socket =
          if action_user.id == user.id, do: socket |> assign(:current_user, user), else: socket

        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
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
