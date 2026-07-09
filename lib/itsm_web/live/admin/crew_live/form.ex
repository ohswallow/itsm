defmodule ItsmWeb.Admin.CrewLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Crews
  alias Itsm.Crews.Crew

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"crew" => crew_params}, socket) do
    changeset = Crews.change_crew(%Crew{}, crew_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"crew" => crew_params}, socket) do
    save_crew(socket, socket.assigns.live_action, crew_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, gettext("New Crew"))
    |> assign(:crew, %Crew{})
    |> assign_new(:form, fn -> to_form(Crews.change_crew(%Crew{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    crew = Crews.get_crew!(id)

    socket
    |> assign(:page_title, gettext("Edit Crew"))
    |> assign(:crew, crew)
    |> assign_new(:form, fn -> to_form(Crews.change_crew(crew)) end)
    |> Itsm.PubSub.Helper.subscribe(Crews, id: id, is_admin: true)
  end

  defp save_crew(socket, :edit, crew_params) do
    %{current_scope: %{user: action_user}, crew: crew} = socket.assigns

    case Crews.update_crew(action_user, crew, crew_params) do
      {:ok, _crew} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/crews")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_crew(socket, :new, crew_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Crews.create_crew(action_user, crew_params) do
      {:ok, _crew} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/crews")}

      {:error, _step, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_crew,
         %{id: id},
         %{assigns: %{crew: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_crew,
         %{id: id},
         %{assigns: %{crew: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/crews")}
  end
end
