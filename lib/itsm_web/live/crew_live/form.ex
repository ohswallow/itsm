defmodule ItsmWeb.CrewLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Crews.Crew
  alias ItsmWeb.LiveUtils

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :new, _params) do
    crew = %Crew{}

    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, crew)
    |> assign(:form, to_form(Crews.change_crew(crew)))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    crew = Crews.get_crew!(id)

    socket
    |> assign(:page_title, "Edit Crew")
    |> assign(:crew, crew)
    |> assign(:form, to_form(Crews.change_crew(crew)))
  end

  def handle_event("validate", %{"crew" => crew_params}, socket) do
    # Crew명 대문자로 변환 => Live view에서 변경하는 방법 대신 Crew.changeset 내부에서 처리하도록 변경
    # crew_params = Map.update(crew_params, "name", "", &String.upcase/1)

    changeset = Crews.change_crew(socket.assigns.crew, crew_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"crew" => crew_params}, socket) do
    save_crew(socket, socket.assigns.live_action, crew_params)
  end

  defp save_crew(socket, :edit, crew_params) do
    %{current_scope: %{user: action_user}, crew: crew} = socket.assigns

    case Crews.update_crew(action_user, crew, crew_params) do
      {:ok, crew} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Crew updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, crew))}

      {:error, step} ->
        {:noreply,
         put_flash(socket, :error, LiveUtils.translate_error(step, :crew, "update_crew"))}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_crew(socket, :new, crew_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Crews.create_crew(action_user, crew_params) do
      {:ok, crew} ->
        {:noreply,
         socket
         |> put_flash(:info, "Crew '#{crew.name}' created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, crew))}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _crew), do: ~p"/crews"
  defp return_path("show", crew), do: ~p"/crews/#{crew}"
end
