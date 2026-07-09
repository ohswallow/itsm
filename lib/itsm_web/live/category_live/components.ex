defmodule ItsmWeb.CategoryLive.Components do
  use ItsmWeb, :live_component

  alias Itsm.Categories

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
            options={@group_select_options}
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
    <.link
      navigate={"/categories/#{@category.id}/#{@category.request_name}/new"}
      id={@id}
    >
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
end
