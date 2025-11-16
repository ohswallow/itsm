defmodule ItsmWeb.TeamLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Team

  def update(%{crew: crew} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Team.change_crew(crew))
     end)}
  end

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
        <input type="hidden" name="crew[leader_id]" value={@current_user.id} />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions><.button phx-disable-with="Saving...">Save Crew</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"crew" => crew_params}, socket) do
    # Crew명 대문자로 변환
    crew_params = Map.update(crew_params, "name", "", &String.upcase/1)

    changeset = Team.change_crew(socket.assigns.crew, crew_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"crew" => crew_params}, socket) do
    IO.inspect(crew_params, label: "crew params")
    save_crew(socket, socket.assigns.action, crew_params)
  end

  defp save_crew(socket, :edit, crew_params) do
    case Team.update_crew(socket.assigns.crew, crew_params) do
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
    case Team.create_crew(socket.assigns.current_user, crew_params) do
      {:ok, crew} ->
        case Team.create_member(%{
               "crew_id" => crew.id,
               "user_id" => socket.assigns.current_user.id
             }) do
          {:ok, _member} ->
            notify_parent({:saved, crew})

            {:noreply,
             socket
             |> put_flash(:info, "Crew created successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, _member_changeset} ->
            # 멤버 추가 실패해도 크루는 만들어졌으니 경고만 띄우고 진행하거나,
            # 원하면 여기서 롤백/삭제를 직접 해도 됨(트랜잭션 안 씀).
            notify_parent({:saved, crew})

            {:noreply,
             socket
             |> put_flash(:warning, "Crew created, but failed to add leader as member")
             |> push_patch(to: socket.assigns.patch)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
