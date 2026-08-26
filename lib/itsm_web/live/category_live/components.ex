defmodule ItsmWeb.CategoryLive.Components do
  use ItsmWeb, :live_component

  alias Itsm.Categories

  def filter_form(assigns) do
    ~H"""
    <.form
      for={@form}
      class="filter gap-2"
      id="filter-form"
      phx-change="filter"
    >
      <.input
        label="서비스 명칭 검색"
        field={@form[:keyword]}
        placeholder="검색어를 입력하세요..."
        autocomplete="off"
        phx-debounce="500"
      />
      <.input
        label="카테고리 그룹"
        type="select"
        field={@form[:group]}
        options={@group_select_options}
        multiple
        size="1"
        phx-hook="InputSelect.selectAll"
        value={(@form[:group] && @form[:group].value) || [""]}
        class="select select-md w-full py-[4.125px]"
      />
      <.input
        label="정렬"
        type="select"
        field={@form[:sort_by]}
        prompt="기본 정렬"
        options={Categories.sort_options()}
        class="select select-md w-full"
      />
      <.button
        patch={~p"/categories"}
        class="btn btn-outline py-1 mt-[19.5px]"
      >
        <.icon name="hero-arrow-path" /> <span>초기화</span>
      </.button>
    </.form>
    """
  end

  # Card component for displaying each category
  attr :category, Itsm.Service.Category, required: true
  attr :id, :string, required: true

  def category_card(assigns) do
    ~H"""
    <div id={@id} class="card card-border bg-base-100 w-96">
      <div class="card-body">
        <h2 class="card-title">{@category.name}</h2>
        
        <p>{@category.description}</p>
        
        <div class="card-actions justify-end">
          <.button
            variant="primary"
            navigate={"/categories/#{@category.id}/#{@category.request_name}/new"}
          >
            신청하기 &gt;
          </.button>
        </div>
      </div>
    </div>
    """
  end
end
