defmodule ItsmWeb.Admin.CommonCodeLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.CommonCodes

  @impl true
  def update(%{common_code: common_code} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(CommonCodes.change_common_code(common_code))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage codes records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="codes-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:group_code]} type="text" label={gettext("Group code")} />
        <.input field={@form[:code]} type="text" label={gettext("Code")} />
        <.input field={@form[:label]} type="text" label={gettext("Label")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:sort_order]} type="number" label={gettext("Sort order")} />
        <.input field={@form[:is_active]} type="checkbox" label={gettext("Is active")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Codes</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"common_code" => common_code_params}, socket) do
    changeset = CommonCodes.change_common_code(socket.assigns.common_code, common_code_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"common_code" => common_code_params}, socket) do
    save_common_code(socket, socket.assigns.action, common_code_params)
  end

  defp save_common_code(socket, :edit, common_code_params) do
    case CommonCodes.update_common_code(socket.assigns.common_code, common_code_params) do
      {:ok, _common_code} ->
        {:noreply,
         socket
         |> put_flash(:info, "Common Code updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_common_code(socket, :new, common_code_params) do
    case CommonCodes.create_common_code(common_code_params) do
      {:ok, _common_code} ->
        {:noreply,
         socket
         |> put_flash(:info, "Common Code created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
