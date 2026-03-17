defmodule ItsmWeb.Admin.CategoryLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Categories

  @impl true
  def update(%{category: category} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Categories.change_category(category))
     end)
     |> assign_new_options()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage category records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="category-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input
          field={@form[:affiliate]}
          type="select"
          label={gettext("Affiliate")}
          prompt="Choose a value"
          options={Itsm.CommonCodes.get_select_options("계열사")}
        /> <.input field={@form[:request_name]} type="text" label={gettext("Request name")} />
        <.input
          field={@form[:group]}
          type="select"
          label={gettext("Group")}
          prompt="Choose a value"
          options={Itsm.CommonCodes.get_select_options("지역_유형")}
        />
        <.input field={@form[:category]} type="text" label={gettext("Category")} />
        <.input
          field={@form[:duration]}
          type="number"
          label={gettext("Duration")}
        />
        <.input field={@form[:active]} type="checkbox" label={gettext("Active")} />
        <.input
          field={@form[:assignee_crew_id]}
          type="select"
          label={gettext("Assignee Crew")}
          prompt="Choose a value"
          options={@assignee_crews_options}
        />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Category</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset = Categories.change_category(socket.assigns.category, category_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.action, category_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:assignee_crews_options, fn -> Itsm.Admin.Crews.get_crew_options() end)
  end

  defp save_category(socket, :edit, category_params) do
    case Categories.update_category(socket.assigns.category, category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(socket, :new, category_params) do
    case Categories.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
