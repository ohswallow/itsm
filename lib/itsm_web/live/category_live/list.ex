defmodule ItsmWeb.CategoryLive.List do
  use ItsmWeb, :live_view

  alias Itsm.Categories

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> stream(:categories, Categories.filter_categories(params), reset: true)
      |> assign(:filtered_category_groups, Categories.get_category_groups(params))
      |> assign(:form, to_form(params))

    {:noreply, socket}
  end

  def render(assigns) do
    # IO.inspect(self(), label: "RENDER")

    ~H"""
    <.filter_form form={@form} />
    <div id="categories-container" class="mt-6 space-y-10">
      <div :for={group <- @filtered_category_groups} class="group-section">
        <div class="relative py-4 border-b border-zinc-100 mb-4">
          <span class="bg-white pr-3 text-sm font-bold text-zinc-800">{group}</span>
        </div>

        <div
          id={"category_card-container_#{group}"}
          phx-update="stream"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6"
        >
          <.category_card
            :for={{dom_id, category} <- @streams.categories}
            :if={category.group == group}
            category={category}
            id={dom_id}
          />
        </div>
      </div>
    </div>
    """
  end

  def filter_form(assigns) do
    ~H"""
    <div class="filter-section">
      <.form
        for={@form}
        class="grid grid-cols-1 md:grid-cols-12 gap-6 items-end"
        id="filter-form"
        phx-change="filter"
      >
        <div class="md:col-span-5">
          <label class="form-label">서비스 명칭 검색</label>
          <.input
            field={@form[:keyword]}
            placeholder="검색어를 입력하세요..."
            autocomplete="off"
            phx-debounce="500"
            class="form-input"
          />
        </div>

        <div class="md:col-span-3">
          <label class="form-label">카테고리 그룹</label>
          <.input
            type="select"
            field={@form[:group]}
            options={[{"그룹", ""}] ++ Itsm.CommonCodes.get_select_options("지역_유형")}
            multiple
            size="1"
            phx-hook="InputSelect.selectAll"
            value={(@form[:group] && @form[:group].value) || [""]}
            class="form-select"
          />
        </div>

        <div class="md:col-span-2">
          <label class="form-label">정렬</label>
          <.input
            type="select"
            field={@form[:sort_by]}
            prompt="기본 정렬"
            options={Categories.sort_options()}
          />
        </div>

        <div class="md:col-span-2 flex justify-end pb-1">
          <.link
            patch={~p"/categories"}
            class="btn-secondary py-2 px-4 text-sm group flex items-center w-full justify-center"
          >
            <.icon
              name="hero-arrow-path"
              class="mr-2 h-4 w-4 group-hover:rotate-180 transition-transform duration-500"
            /> <span>초기화</span>
          </.link>
        </div>
      </.form>
    </div>
    """
  end

  # Card component for displaying each category
  attr :category, Itsm.Service.Category, required: true
  attr :id, :string, required: true

  def category_card(assigns) do
    ~H"""
    <.link navigate={"/categories/#{@category.id}/#{@category.request_name}/new"} id={@id}>
      <div class="card-interactive shrink-0 lg:w-72">
        <span class="badge badge-deposit">가상</span>
        <h3 class="text-title-h3 mt-3">{@category.name}</h3>

        <p class="text-caption mt-1 h-10">{@category.description}</p>

        <div class="text-right mt-4">
          <span class="btn-text inline-flex items-center group-hover:text-kb-yellow transition-colors">
            신청하기 &gt;
          </span>
        </div>
      </div>
    </.link>
    """
  end

  def handle_event("filter", params, socket) do
    # URL 파라미터를 깔끔하게 정리
    params =
      params
      |> Map.take(~w(keyword group sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)

    # push_patch는 현재 URL을 변경하고, 페이지를 새로고침하지 않음
    # 이 경우, 현재 LiveView의 상태를 유지하면서 URL만 업데이트
    socket = push_patch(socket, to: ~p"/categories?#{params}")

    {:noreply, socket}
  end
end
