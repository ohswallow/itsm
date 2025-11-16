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
    users = Accounts.search_users(%{"q" => text})

    options =
      Enum.map(users, fn user ->
        %{
          # label: user.display_name,
          # tag_label: "#{user.display_name} (#{user.email})",
          tag_label: user.display_name,
          label: "#{user.display_name} (#{user.id})",
          value: user.id,
          # value: to_string(user.id),
          email: user.email,
          organization: user.organization,
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
