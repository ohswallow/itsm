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

  # 이름만 나오는 기존 코드
  # def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
  #   IO.inspect(text, label: "Searching for")
  #   users = Accounts.search_users(%{"q" => text})

  #   send_update(LiveSelect.Component,
  #     id: live_select_id,
  #     options: Enum.map(users, &{&1.display_name, &1.id})
  #   )

  #   {:noreply, socket}
  # end

  # 추가 정보를 포함한 옵션 생성
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    IO.inspect(text, label: "Searching for")
    # users = Accounts.search_users(%{"q" => text})

    # ✅ 현재 로그인한 사용자 정보 가져오기
    current_user = socket.assigns.current_user

    # ✅ 검색 조건에 조직/부서 코드 추가
    search_params = %{
      "q" => text,
      "organization_code" => current_user.organization_code,
      "department_code" => current_user.department_code
    }

    # 변경된 파라미터로 검색 요청
    users = Accounts.search_users(search_params)

    options =
      Enum.map(users, fn user ->
        %{
          # 기본 표시 텍스트 (필요 시 커스텀 가능)
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

  # 유저를 선택했을 때 호출
  def handle_event(
        "submit",
        %{"user_search_text_input" => _user_name, "user_search" => user_id} = params,
        socket
      ) do
    IO.inspect(params, label: "Selected params")

    # user_id로 다시 조회해서 모든 정보 가져오기
    user = Accounts.get_user!(user_id)

    IO.puts("You selected #{user.display_name}, #{user.id}, #{user.employee_number}")

    # 부모에게 메시지 전송
    send(self(), {__MODULE__, :user_selected, user})

    {:noreply, socket}
  end
end
