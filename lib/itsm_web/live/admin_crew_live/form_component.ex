defmodule ItsmWeb.AdminCrewLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Team
  alias Itsm.Admin.Crews

  @impl true
  def update(%{crew: crew} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Crews.change_crew(crew))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage crew records in your database.</:subtitle>
      </.header>
      
      <.simple_form
        for={@form}
        id="crew-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions><.button phx-disable-with="Saving...">Save Crew</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"crew" => crew_params}, socket) do
    changeset = Crews.change_crew(socket.assigns.crew, crew_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"crew" => crew_params}, socket) do
    save_crew(socket, socket.assigns.action, crew_params)
  end

  defp save_crew(socket, :edit, crew_params) do
    case Crews.update_crew(socket.assigns.crew, crew_params) do
      {:ok, crew} ->
        notify_parent({:saved, crew})

        {:noreply,
         socket
         |> put_flash(:info, "Crew updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_crew(socket, :new, crew_params) do
    current_user = socket.assigns.current_user

    case Team.create_crew(crew_params, current_user) do
      {:ok, crew} ->
        notify_parent({:saved, crew})

        {:noreply,
         socket
         |> put_flash(:info, "Crew created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
