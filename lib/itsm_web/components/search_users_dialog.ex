defmodule ItsmWeb.SearchUsersDialog do
  use ItsmWeb, :live_component

  alias Itsm.Accounts

  @doc """
  사용자 검색을 위한 라이브 컴포넌트입니다.
  """
  attr :id, :string, required: true
  attr :current_scope, :any, required: true
  attr :opts, :list, default: [], doc: "{:exclude_crew, Crew.t()} 크루원을 제외하고 검색한다"
  attr :rest, :global

  def search(assigns) do
    ~H"""
    <.live_component
      id={@id}
      current_scope={@current_scope}
      opts={@opts}
      module={__MODULE__}
    />
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(%{"user_search" => []}))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="search-users-form"
        phx-submit="submit"
        phx-target={@myself}
      >
        <div class="flex items-end w-full">
          <LiveSelect.live_select
            field={@form[:user_search]}
            phx-target={@myself}
            allow_clear={true}
            mode={:tags}
            placeholder={gettext("Please search for the name")}
            debounce={300}
            container_class="relative w-full"
            text_input_class="input input-bordered w-full focus:input-primary"
            dropdown_class="absolute z-[100] menu bg-base-100 border border-base-300 w-full rounded-box shadow-xl max-h-60 overflow-y-auto mt-1 p-2"
            option_class="rounded-lg p-2 cursor-pointer hover:bg-base-200"
            active_option_class="bg-primary text-primary-content font-semibold"
            tag_class="flex items-center gap-1 mb-1"
          >
            <:option :let={option}>
              <div class="flex flex-col">
                <span class="font-bold">
                  {option.label} <span class="text-xs opacity-70">({option.employee_number})</span>
                </span>
                 <span class="text-xs opacity-60 mt-0.5">{option.department} | {option.email}</span>
              </div>
            </:option>
            
            <:tag :let={option}>
              <div class="badge badge-primary gap-1 p-3">
                {option.tag_label}
              </div>
            </:tag>
          </LiveSelect.live_select>
           <.button>{gettext("Add")}</.button>
        </div>
      </.form>
    </div>
    """
  end

  # 1. [검색] Context가 이미 포맷팅된 Map 리스트를 줍니다. 그대로 넘기면 됩니다.
  def handle_event("live_select_change", %{"text" => keyword, "id" => live_select_id}, socket) do
    %{current_scope: %{user: user}, opts: opts} = socket.assigns

    options = Accounts.live_select_by_name(user, keyword, opts)

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  def handle_event("submit", %{"user_search" => users_id}, socket) do
    send(self(), {__MODULE__, :users_selected, users_id})

    {:noreply, socket}
  end

  def handle_event("submit", %{"[user_search_empty_selection]" => _}, socket) do
    {:noreply, socket}
  end
end
