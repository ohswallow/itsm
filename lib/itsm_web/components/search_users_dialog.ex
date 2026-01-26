defmodule ItsmWeb.SearchUsersDialog do
  use ItsmWeb, :live_component

  alias Itsm.Accounts

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      # 다건 선택(tags)이므로 초기값은 빈 리스트
      |> assign(:form, to_form(%{"user_search" => []}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="dialog">
      <h1 class="mb-2">멤버 추가</h1>
      
      <.form
        for={@form}
        id="search-users-form"
        phx-submit="submit"
        phx-target={@myself}
        class="flex items-center space-x-2"
      >
        <LiveSelect.live_select
          field={@form[:user_search]}
          phx-target={@myself}
          allow_clear={true}
          mode={:tags}
          placeholder="이름을 검색하세요"
          container_extra_class="flex-grow"
          dropdown_extra_class="bg-white shadow-lg w-full max-h-60 overflow-y-auto z-50"
          option_extra_class="text-gray-800 border-b border-gray-200 hover:bg-blue-100 py-2 px-4"
          active_option_class="bg-blue-500 text-white"
          tags_container_extra_class="flex flex-wrap gap-2 items-start max-h-28 overflow-y-auto pr-2"
          debounce={300}
        >
          <:clear_button>&times;</:clear_button> <%!-- 드롭다운 옵션 디자인 --%>
          <:option :let={option}>
            <div class="flex flex-col">
              <span class="font-bold">
                {option.label} <span class="text-xs font-normal">({option.employee_number})</span>
              </span> <span class="text-xs text-gray-500">{option.department} | {option.email}</span>
            </div>
          </:option>
           <%!-- 선택된 태그 디자인 (tag_label 사용) --%>
          <:tag :let={option}>
            <div class="flex items-center bg-blue-100 text-blue-800 mb-1 border border-blue-200 px-2 py-1 rounded-full text-sm">
              <span class="font-medium mr-1">{option.tag_label}</span>
            </div>
          </:tag>
        </LiveSelect.live_select>
         <.button phx-disable-with="Adding...">Add</.button>
      </.form>
    </div>
    """
  end

  # 1. [검색] Context가 이미 포맷팅된 Map 리스트를 줍니다. 그대로 넘기면 됩니다.
  def handle_event("live_select_change", %{"text" => keyword, "id" => live_select_id}, socket) do
    %{current_user: user} = socket.assigns

    # Context 호출 (Admin/General 분기 로직은 Context 내부에 있음)
    options = Accounts.search_user_options(user, %{"keyword" => keyword})

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  # 2. [제출] 부모에게 ID 리스트만 던집니다.
  def handle_event("submit", %{"user_search" => users_id}, socket) do
    # users_id는 ["id1", "id2"] 형태
    send(self(), {__MODULE__, :users_selected, users_id})

    {:noreply, socket}
  end
end
