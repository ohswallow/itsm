defmodule ItsmWeb.TeamLive.MyIndex do
  use ItsmWeb, :live_view

  alias Itsm.Team
  alias Itsm.Team.Crew

  # 공통 컴포넌트 임포트
  import ItsmWeb.TeamLive.TableComponents

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, stream(socket, :crews, Team.list_my_crews(current_user))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # 1. 목록 조회 (:index)
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Crews")
    # 모달이 없으므로 nil
    |> assign(:crew, nil)
  end

  # 2. 생성 모달 (:new)
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Crew")
    # 빈 구조체 전달
    |> assign(:crew, %Crew{})
  end

  # 3. 수정 모달 (:edit)
  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Crew")
    # 수정할 데이터 로딩
    |> assign(:crew, Team.get_crew!(id))
  end

  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:actions>
        <.button phx-click={JS.dispatch("click", to: {:inner, "a"})}>
          <.link patch={~p"/crews/new"}>New Crew</.link>
        </.button>
      </:actions>
    </.header>

    <.crew_table
      crews={@streams.crews}
      row_click={
        fn {_id, crew} ->
          JS.navigate(~p"/crews/#{crew}?return_to=my")
        end
      }
    >
      <:action :let={{_id, crew}} label="Actions">
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
      </:action>
    </.crew_table>

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
    current_user = socket.assigns.current_user

    case Team.delete_crew(crew, current_user) do
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
end
