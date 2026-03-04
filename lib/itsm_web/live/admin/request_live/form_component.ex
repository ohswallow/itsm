defmodule ItsmWeb.Admin.RequestLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Requests

  @impl true
  def update(%{request: request} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Requests.change_request(request))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage request records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="request-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label={gettext("Title")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:env]} type="text" label={gettext("Environment")} />
        <.itsm_calendar
          field={@form[:due_date]}
          label={gettext("Due Date")}
          show_time
          default_selected_date_time={@form[:due_date].value}
        />
        <.input
          field={@form[:category_id]}
          type="select"
          label={gettext("Category")}
          prompt="Choose a value"
          options={Itsm.Admin.Categories.list_categories() |> Enum.map(&{&1.name, &1.id})}
        />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions><.button phx-disable-with="Saving...">Save Request</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = Requests.change_request(socket.assigns.request, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    case Requests.update_request(socket.assigns.request, request_params) do
      {:ok, request} ->
        notify_parent({:saved, request})

        {:noreply,
         socket
         |> put_flash(:info, "Request updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    case Requests.create_request(socket.assigns.current_user, request_params) do
      {:ok, request} ->
        notify_parent({:saved, request})

        {:noreply,
         socket
         |> put_flash(:info, "Request created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
