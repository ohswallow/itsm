defmodule ItsmWeb.ApprovalLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Service

  @impl true
  def update(%{approval: approval} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Service.change_approval(approval))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage approval records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="approval-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Service.Approval, :status)}
        />
        <.input field={@form[:approver_id]} type="text" label="Approver" />
        <.input field={@form[:approver_name]} type="text" label="Approver name" />
        <.input field={@form[:comment]} type="text" label="Comment" />
        <.input field={@form[:approved_at]} type="datetime-local" label="Approved at" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Approval</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"approval" => approval_params}, socket) do
    changeset = Service.change_approval(socket.assigns.approval, approval_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"approval" => approval_params}, socket) do
    save_approval(socket, socket.assigns.action, approval_params)
  end

  defp save_approval(socket, :edit, approval_params) do
    case Service.update_approval(socket.assigns.approval, approval_params) do
      {:ok, approval} ->
        notify_parent({:saved, approval})

        {:noreply,
         socket
         |> put_flash(:info, "Approval updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_approval(socket, :new, approval_params) do
    case Service.create_approval(approval_params) do
      {:ok, approval} ->
        notify_parent({:saved, approval})

        {:noreply,
         socket
         |> put_flash(:info, "Approval created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
