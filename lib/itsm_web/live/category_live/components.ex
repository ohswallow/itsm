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
  # attr :category, Itsm.Service.Category, required: true
  # attr :id, :string, required: true

  # def category_card(assigns) do
  #   ~H"""
  #   <.link
  #     navigate={"/categories/#{@category.id}/#{@category.request_name}/new"}
  #     id={@id}
  #   >
  #     <div class="card-interactive shrink-0 lg:w-72">
  #       <span class="badge badge-deposit">가상</span>
  #       <h3 class="text-title-h3 mt-3">{@category.name}</h3>

  #       <p class="text-caption mt-1 h-10">{@category.description}</p>

  #       <div class="text-right mt-4">
  #         <span class="btn-text inline-flex items-center group-hover:text-kb-yellow transition-colors">
  #           신청하기 &gt;
  #         </span>
  #       </div>
  #     </div>
  #   </.link>
  #   """
  # end
  attr :category, Itsm.Service.Category, required: true

  def category_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/categories/#{@category.id}/#{@category.request_name}/new"}
      class="group block h-full rounded-2xl focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
    >
      <article class="card h-full border border-base-300 bg-base-100 shadow-sm transition duration-200 hover:-translate-y-1 hover:border-primary/40 hover:shadow-lg">
        <div class="card-body gap-3 p-6">
          <div class="flex items-start justify-between gap-3">
            <span class="badge badge-primary badge-outline">
              {@category.group}
            </span>
            
            <.icon
              name="hero-arrow-up-right"
              class="size-5 text-base-content/30 transition group-hover:text-primary"
            />
          </div>
          
          <h3 class="card-title text-lg leading-7">
            {@category.name}
          </h3>
          
          <p class="min-h-12 text-sm leading-6 text-base-content/65">
            {@category.description || "서비스 신청서를 작성합니다."}
          </p>
          
          <div class="card-actions mt-auto justify-end pt-2">
            <span class="inline-flex items-center gap-1 text-sm font-semibold text-primary">
              신청하기
              <.icon
                name="hero-arrow-right"
                class="size-4 transition-transform group-hover:translate-x-1"
              />
            </span>
          </div>
        </div>
      </article>
    </.link>
    """
  end
end
