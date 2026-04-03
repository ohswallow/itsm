defmodule ItsmWeb.Admin.CrewLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Crews

  @impl true
  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  @impl true
  def update(%{crew: crew} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
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

      <div
        :if={@conflict}
        class="p-4 mb-4 bg-red-50 border border-red-200 text-red-800 rounded animate-pulse"
      >
        <div class="flex items-center gap-2 font-bold">
          <span>⚠️ 충돌 발생!</span>
        </div>
        <p class="mt-1 text-sm">{@conflict_msg}</p>
        <p class="mt-2 text-xs opacity-75">현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </div>

      <.simple_form
        for={@form}
        id="crew-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Crew</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"crew" => crew_params}, socket) do
    changeset = Crews.change_crew(socket.assigns.crew, crew_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"crew" => crew_params}, socket) do
    save_crew(socket, socket.assigns.action, crew_params)
  end

  defp save_crew(socket, :edit, crew_params) do
    case Crews.update_crew(socket.assigns.crew, crew_params) do
      {:ok, _crew} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_crew(socket, :new, crew_params) do
    current_user = socket.assigns.current_user

    case Crews.create_crew(current_user, crew_params) do
      {:ok, _crew} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
