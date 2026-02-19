defmodule ItsmWeb.AdminCommonCodeLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.CommonCodes

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
        <.input field={@form[:group_code]} type="text" label="Group code" />
        <.input field={@form[:code]} type="text" label="Code" />
        <.input field={@form[:label]} type="text" label="Label" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:sort_order]} type="number" label="Sort order" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Codes</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

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
  def handle_event("validate", %{"common_code" => common_code_params}, socket) do
    changeset = CommonCodes.change_common_code(socket.assigns.common_code, common_code_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"common_code" => common_code_params}, socket) do
    save_common_code(socket, socket.assigns.action, common_code_params)
  end

  defp save_common_code(socket, :edit, common_code_params) do
    case CommonCodes.update_common_code(socket.assigns.common_code, common_code_params) do
      {:ok, common_code} ->
        notify_parent({:saved, common_code})

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
      {:ok, common_code} ->
        notify_parent({:saved, common_code})

        {:noreply,
         socket
         |> put_flash(:info, "Common Code created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
