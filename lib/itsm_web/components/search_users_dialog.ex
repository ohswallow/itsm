defmodule ItsmWeb.SearchUsersDialog do
  use ItsmWeb, :live_component

  import LiveSelect
  alias Itsm.Accounts

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(%{"user_search" => []}))

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
          mode={:tags}
          placeholder="사용자 이름을 입력하세요"
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
                ID: {option.value} | Email: {option.email} | Organization: {option.organization}
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

    # ✅ 1. 현재 로그인한 사용자 정보 가져오기
    current_user = socket.assigns.current_user

    # ✅ 2. 검색 조건(Map) 만들기
    # Admin 여부에 따라 검색 조건 다르게 설정
    search_params =
      if current_user.role == :admin do
        # 관리자(Admin)인 경우:
        # 이름 검색어("q")만 보내고, 조직/부서 코드는 보내지 않음 (전체 User 검색)
        %{"q" => text}
      else
        # 일반 사용자(General 등)인 경우:
        # 내 계열사/부서 코드를 함께 보냄 (같은 계열사/부서 내 User 검색)
        %{
          "q" => text,
          "organization_code" => current_user.organization_code,
          "department_code" => current_user.department_code
        }
      end

    # ✅ 3. 수정된 파라미터로 검색 요청
    users = Accounts.search_users(search_params)

    # users = Accounts.search_users(%{"q" => text})

    options =
      Enum.map(users, fn user ->
        %{
          # 기본 표시 텍스트
          tag_label: user.display_name,
          label: user.display_name,
          # 선택 시 사용되는 값
          value: user.id,
          email: user.email,
          organization: user.organization,
          department: user.department,
          employee_number: user.employee_number
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
        %{"user_search" => users_id} = params,
        socket
      ) do
    IO.inspect(params, label: "Selected params")

    # users_id는 리스트: ["id1", "id2", ...]
    users = Enum.map(users_id, &Accounts.get_user!/1)

    Enum.each(users, fn user ->
      IO.puts("You selected #{user.display_name}, #{user.id}, #{user.employee_number}")
    end)

    # 부모에게 선택된 모든 사용자 전송
    send(
      socket.assigns.parent_pid,
      {:users_selected, users_id}
    )

    {:noreply, socket}
  end
end
