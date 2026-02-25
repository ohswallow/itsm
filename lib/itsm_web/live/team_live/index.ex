defmodule ItsmWeb.TeamLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Crews
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
    |> assign(:current_tab, :my)
    |> stream(:crews, Crews.list_my_crews(socket.assigns.current_user), reset: true)
  end

  defp apply_action(socket, :all, params) do
    socket
    |> assign(:page_title, "All Crews")
    |> assign(:referrer, ~p"/crews/all")
    |> assign(:current_tab, :all)
    |> stream(:crews, Crews.filter_crews(params), reset: true)
    |> assign(:form, to_form(params))
  end

  defp apply_action(socket, :edit, %{"id" => crew_id}) do
    socket
    |> assign(:page_title, "Edit Crews")
    |> assign(:crew, Crews.get_crew!(crew_id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    |> assign(:crew, %Crew{})
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:actions :if={@current_tab == :my}>
        <.button phx-click={JS.dispatch("click", to: {:inner, "a"})}>
          <.link patch={~p"/crews/new"}>New Crew</.link>
        </.button>
      </:actions>
    </.header>
    <.filter_form :if={@current_tab == :all} form={@form} />
    <.table
      id="crews"
      rows={@streams.crews}
      row_click={
        fn {_id, crew} ->
          JS.navigate(~p"/crews/#{crew}?referrer=#{@referrer}")
        end
      }
    >
      <:col :let={{_id, crew}} label={gettext("Name")}>{crew.name}</:col>

      <:col :let={{_id, crew}} label={gettext("Description")}>{crew.description}</:col>

      <:col :let={{_id, crew}} :if={@current_tab == :all} label={gettext("Organization")}>
        {Itsm.CommonCodes.get_label("계열사", crew.leader.organization_code)}
      </:col>

      <:col :let={{_id, crew}} :if={@current_tab == :all} label={gettext("Department")}>
        {crew.leader.department}
      </:col>

      <:col :let={{_id, crew}} label={gettext("Leader")}>
        {crew.leader.display_name} <span class="text-xs text-gray-400">({crew.leader_id})</span>
      </:col>
      <%!-- :my 일때만 보이게, :all 일때는 안보임 --%>
      <:col :let={{_id, crew}} :if={@current_tab == :my} label={gettext("Actions")}>
        <.dropdown_menu id={"#{crew.id}-menu"}>
          <.link
            patch={~p"/crews/#{crew}/edit"}
            class="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
          >
            <.icon name="hero-pencil" class="w-4 h-4" /> Edit Crew
          </.link>
          <.link
            phx-click={JS.push("delete", value: %{id: crew.id})}
            data-confirm="Are you sure?"
            class="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
          >
            <.icon name="hero-trash" class="w-4 h-4" /> Delete Crew
          </.link>
        </.dropdown_menu>
      </:col>
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

  def filter_form(assigns) do
    ~H"""
    <.form
      for={@form}
      class="sm:flex justify-center gap-4 items-cente mt-2"
      id="filter-form"
      phx-change="filter"
    >
      <.input field={@form[:q]} placeholder="Search..." autocomplete="off" phx-debounce="500" />
      <.input
        type="select"
        field={@form[:organization]}
        prompt="Organization"
        options={["KB국민은행", "KB국민카드", "KB캐피탈", "KB증권"]}
      /> <%!-- navigate 대신 patch를 사용하여 URL을 변경 --%>
      <.link patch={~p"/crews/all"} class="flex items-center hover:underline">Reset</.link>
    </.form>
    """
  end

  def handle_info({ItsmWeb.TeamLive.FormComponent, {:saved, crew}}, socket) do
    {:noreply, stream_insert(socket, :crews, crew)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    crew = Crews.get_crew!(id)
    current_user = socket.assigns.current_user

    case Crews.delete_crew(crew, current_user) do
      {:ok, _} ->
        # {:noreply, stream_delete(socket, :crews, crew)}
        {:noreply,
         socket
         |> stream_delete(:crews, crew)
         |> put_flash(:info, gettext("Crew deleted successfully."))}

      # 권한 없는 사용자가 삭제 시도할 때
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Only the leader can delete this crew."))
         |> push_navigate(to: ~p"/crews", replace: true)}

      # 기타 오류 처리
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("An unknown error occurred."))}
    end
  end

  def handle_event("filter", params, socket) do
    # URL 파라미터를 깔끔하게 정리
    params =
      params
      |> Map.take(~w(q organization))
      |> Map.reject(fn {_, v} -> v == "" end)

    # push_patch는 현재 URL을 변경하고, 페이지를 새로고침하지 않음
    # 이 경우, 현재 LiveView의 상태를 유지하면서 URL만 업데이트
    socket = push_patch(socket, to: ~p"/crews/all?#{params}")

    {:noreply, socket}
  end
end
