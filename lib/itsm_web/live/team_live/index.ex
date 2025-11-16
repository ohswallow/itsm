defmodule ItsmWeb.TeamLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Team
  alias Itsm.Team.Crew

  def mount(_params, _session, socket) do
    # {:ok, socket}
    {:ok, stream(socket, :crews, [])}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :my, _params) do
    socket
    |> assign(:page_title, "My Crews")
    |> assign(:referrer, ~p"/crews")
    |> stream(:crews, Team.list_my_crews(socket.assigns.current_user), reset: true)
  end

  defp apply_action(socket, :all, _params) do
    socket
    |> assign(:page_title, "All Crews")
    |> assign(:referrer, ~p"/crews/all")
    |> stream(:crews, Team.list_crews(), reset: true)
  end

  defp apply_action(socket, :edit, %{"id" => crew_id}) do
    socket
    |> assign(:page_title, "Edit Crews")
    |> assign(:crew, Team.get_crew!(crew_id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  def render(assigns) do
    ~H"""
    <.header>
      Listing Crews
      <:actions>
        <.button phx-click={JS.dispatch("click", to: {:inner, "a"})}>
          <%!-- <.link navigate={~p"/crews/new"}>New Crew</.link> --%>
          <.link patch={~p"/crews/new"}>New Crew</.link>
        </.button>
      </:actions>
    </.header>

    <%!-- <.table
      id="crews"
      rows={@streams.crews}
      row_click={fn {_id, crew} -> JS.navigate(~p"/crews/#{crew}") end}
    > --%>
    <.table
      id="crews"
      rows={@streams.crews}
      row_click={
        fn {_id, crew} ->
          JS.navigate(~p"/crews/#{crew}?referrer=#{@referrer}")
        end
      }
    >
      <:col :let={{_id, crew}} label="Name">{crew.name}</:col>
      
      <:col :let={{_id, crew}} label="Description">{crew.description}</:col>
      
      <:col :let={{id, crew}} label="Actions">
        <%!-- <%= if crew.leader_id == @current_user.id do %> --%>
        <%!-- leader일때만 드롭박스 보임 --%>
        <.dropdown_menu id={"#{crew.id}-menu"}>
          <.link
            patch={~p"/crews/#{crew}/edit"}
            class="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
          >
            <.icon name="hero-pencil" class="w-4 h-4" /> Edit Crew
          </.link>
          <%!-- <button
            type="button"
            phx-click={JS.push("delete", value: %{id: crew.id}) |> hide("##{id}")}
            phx-value-id={crew.id}
            data-confirm="Are you sure you want to delete the crew?"
            class="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
          >
            <.icon name="hero-trash" class="w-4 h-4" /> Delete Crew
          </button> --%>
          <.link
            phx-click={JS.push("delete", value: %{id: crew.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
            class="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
          >
            <.icon name="hero-trash" class="w-4 h-4" /> Delete Crew
          </.link>
        </.dropdown_menu>
         <%!-- <% end %> --%>
      </:col>
      
      <%!-- <:action :let={{_id, crew}}>
        <div class="sr-only"><.link navigate={~p"/crews/#{crew}"}>Show</.link></div>
         <.link patch={~p"/crews/#{crew}/edit"}>Edit</.link>
      </:action>

      <:action :let={{id, crew}}>
        <.link
          phx-click={JS.push("delete", value: %{id: crew.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action> --%>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="crew-modal"
      show
      on_cancel={JS.patch(~p"/crews")}
    >
      <.live_component
        module={ItsmWeb.TeamLive.FormComponent}
        id={@crew.id || :new}
        title={@page_title}
        action={@live_action}
        crew={@crew}
        current_user={@current_user}
        patch={~p"/crews"}
      />
    </.modal>
    """
  end

  def handle_info({ItsmWeb.TeamLive.FormComponent, {:saved, crew}}, socket) do
    {:noreply, stream_insert(socket, :crews, crew)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    crew = Team.get_crew!(id)
    {:ok, _} = Team.delete_crew(crew)

    {:noreply, stream_delete(socket, :crews, crew)}
  end
end
