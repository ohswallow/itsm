defmodule ItsmWeb.CrewLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Crews
  alias ItsmWeb.LiveUtils

  def update(%{crew: crew} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Crews.change_crew(crew))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage crew records in your database.</:subtitle>
      </.header>
      
      <.form
        for={@form}
        id="crew-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions><.button phx-disable-with="Saving...">Save Crew</.button></:actions>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"crew" => crew_params}, socket) do
    # Crew명 대문자로 변환 => Live view에서 변경하는 방법 대신 Crew.changeset 내부에서 처리하도록 변경
    # crew_params = Map.update(crew_params, "name", "", &String.upcase/1)

    changeset = Crews.change_crew(socket.assigns.crew, crew_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"crew" => crew_params}, socket) do
    save_crew(socket, socket.assigns.action, crew_params)
  end

  defp save_crew(socket, :edit, crew_params) do
    %{current_user: action_user, crew: crew} = socket.assigns

    case Crews.update_crew(action_user, crew, crew_params) do
      {:ok, crew} ->
        notify_parent({:saved, crew})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Crew updated successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, step} ->
        {:noreply,
         socket
         |> put_flash(:error, LiveUtils.translate_error(step, :crew, "update_crew"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_crew(socket, :new, crew_params) do
    %{current_user: action_user} = socket.assigns

    case Crews.create_crew(action_user, crew_params) do
      {:ok, crew} ->
        notify_parent({:saved, crew})

        {:noreply,
         socket
         |> put_flash(:info, "Crew '#{crew.name}' created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
