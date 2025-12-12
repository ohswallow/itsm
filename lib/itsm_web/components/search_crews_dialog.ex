defmodule ItsmWeb.SearchCrewsDialog do
  use ItsmWeb, :live_component

  import LiveSelect
  alias Itsm.Accounts
  # alias Itsm.Team.Crew
  # alias Itsm.Team.Member
  alias Itsm.Team

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(%{"crew_search" => []}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="dialog">
      <h1 class="mb-2">Crew 검색</h1>
      
      <.form
        for={@form}
        id="search-form"
        phx-submit="submit"
        phx-target={@myself}
        class="flex items-center space-x-2"
      >
        <.live_select
          field={@form[:crew_search]}
          phx-target={@myself}
          allow_clear={true}
          mode={:tags}
          placeholder="Crew명 또는 Member 이름을 입력하세요"
          container_extra_class="flex-grow"
          dropdown_extra_class="bg-white shadow-lg w-full max-h-60 overflow-y-auto"
          option_extra_class="text-gray-800 border-b border-gray-200 hover:bg-blue-100 py-2 px-4"
          active_option_class="bg-blue-500 text-white"
          tags_container_extra_class="flex flex-wrap gap-2 items-start max-h-28 overflow-y-auto pr-2"
        >
          <:option :let={option}>
            <div class="flex flex-col">
              <span class="font-bold">{option.label}</span>
              <span class="text-sm text-gray-600">
                <%!-- ID: {option.value} | Email: {option.email} | Organization: {option.organization} --%> {option.description}
              </span>
            </div>
          </:option>
          
          <:tag :let={option}>
            <div class="flex items-center bg-blue-500 mb-1 text-white px-3 py-1 rounded-full">
              <span>{option.tag_label}</span>
            </div>
          </:tag>
        </.live_select>
         <.button phx-disable-with="submitting...">Submit</.button>
      </.form>
    </div>
    """
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    IO.inspect(text, label: "Searching for")
    # 1. Crew 이름으로 직접 검색
    crews_by_name = Team.search_crews_by_name(text)

    # 2. Member 이름(user.display_name)으로 검색 - Member를 통해 Crew 찾기
    users = Accounts.search_users(%{"q" => text})
    crews_by_member = Team.search_crews_by_member(users)

    # 3. 중복 제거 (crew id 기준)
    crews =
      (crews_by_name ++ crews_by_member)
      |> Enum.uniq_by(& &1.id)

    options =
      Enum.map(crews, fn crew ->
        %{
          label: crew.name,
          tag_label: crew.name,
          value: crew.id,
          description: crew.description
        }
      end)

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: options
    )

    {:noreply, socket}
  end

  def handle_event(
        "submit",
        %{"crew_search" => crews_id} = params,
        socket
      ) do
    IO.inspect(params, label: "Selected params")

    crews = Enum.map(crews_id, &Itsm.Team.get_crew!/1)

    Enum.each(crews, fn crew ->
      IO.puts("You selected crew: #{crew.name}")
    end)

    # 부모에게 선택된 모든 사용자 전송
    send(self(), {__MODULE__, :crews_selected, crews_id})

    {:noreply, socket}
  end
end
