defmodule ItsmWeb.SearchUserDialog do
  use ItsmWeb, :live_component

  import LiveSelect
  alias Itsm.Accounts

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(%{"user_search" => nil}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="dialog">
      <h1 class="mb-2">User 검색</h1>
      
      <.form
        for={@form}
        id="search-form"
        phx-submit="submit"
        phx-target={@myself}
        class="flex items-center space-x-2"
      >
        <.live_select
          field={@form[:user_search]}
          phx-target={@myself}
          allow_clear={true}
          mode={:single}
          placeholder="사용자 이름을 입력하세요"
          container_extra_class="flex-grow"
          dropdown_extra_class="bg-white shadow-lg w-full max-h-60 overflow-y-auto"
          option_extra_class="text-gray-800 border-b border-gray-200 hover:bg-blue-100 py-2 px-4"
          active_option_class="bg-blue-500 text-white"
          debounce={300}
        >
          <:clear_button>&times;</:clear_button>
          <:option :let={option}>
            <%!-- 이름 외 옵션 표출 --%>
            <div class="flex flex-col">
              <span class="font-bold">{option.label}</span>
              <span class="text-sm text-gray-600">
                ID: {option.value} | Email: {option.email} | Organization: {option.organization}
              </span>
            </div>
          </:option>
        </.live_select>
         <.button phx-disable-with="submitting...">Submit</.button>
      </.form>
    </div>
    """
  end

  # 유저 검색 시 text박스 입력시 호출
  def handle_event("live_select_change", %{"text" => keyword, "id" => live_select_id}, socket) do
    %{current_user: user} = socket.assigns
    options = Accounts.search_user_options(user, %{"keyword" => keyword})
    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  # 유저를 선택했을 때 호출
  def handle_event("submit", %{"user_search" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    send(self(), {__MODULE__, :user_selected, user})

    {:noreply, socket}
  end
end
