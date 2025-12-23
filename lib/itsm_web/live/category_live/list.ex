defmodule ItsmWeb.CategoryLive.List do
  use ItsmWeb, :live_view

  alias Itsm.Service

  def mount(_params, _session, socket) do
    # socket = assign(socket, :categories, Service.list_categories())
    # IO.inspect(self(), label: "MOUNT")
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    # IO.inspect(self(), label: "HANDLE_PARAMS")

    socket =
      socket
      |> stream(:categories, Service.filter_categories(params), reset: true)
      # |> assign(:form, to_form(%{}))
      |> assign(:form, to_form(params))

    {:noreply, socket}
  end

  def render(assigns) do
    # IO.inspect(self(), label: "RENDER")

    ~H"""
    <.filter_form form={@form} />
    <div
      class="mt-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6"
      id="categories"
      phx-update="stream"
    >
      <.category_card
        :for={{dom_id, category} <- @streams.categories}
        category={category}
        id={dom_id}
      />
    </div>
    """
  end

  def filter_form(assigns) do
    ~H"""
    <.form
      for={@form}
      class="sm:flex justify-center gap-4 items-cente mt-2"
      id="filter-form"
      phx-change="filter"
    >
      <.input field={@form[:q]} placeholder="Search..." autocomplete="off" phx-debounce="500" />
      <.input
        type="select"
        field={@form[:group]}
        prompt="Group"
        options={[:K_리전_공동존, :K_리전_은행존, :배치자동화, :P_리전]}
      />
      <.input
        type="select"
        field={@form[:sort_by]}
        prompt="Sort By"
        options={[
          Name: "name",
          "Description: High to Low": "description_desc",
          "Description: Low to High": "description_asc"
        ]}
      /> <%!-- <.link navigate={~p"/categories"} class="flex items-center hover:underline"> --%>
      <%!-- navigate 대신 patch를 사용하여 URL을 변경 --%>
      <.link patch={~p"/categories"} class="flex items-center hover:underline">Reset</.link>
    </.form>
    """
  end

  # Card component for displaying each category
  attr :category, Itsm.Service.Category, required: true
  attr :id, :string, required: true

  def category_card(assigns) do
    ~H"""
    <%!-- <.link navigate={~p"/categories/#{@category}"} id={@id}> --%>
    <.link navigate={"/categories/#{@category.id}/#{@category.request_name}/new"} id={@id}>
      <div class="w-full h-60 bg-white rounded-2xl shadow-sm border border-gray-200 hover:shadow-md transition-shadow p-6 flex flex-col justify-between relative lg:w-60">
        <div class="flex items-center justify-between"></div>
        <!-- 제목 및 설명 -->
        <div class="mt-2">
          <h3 class="text-base font-semibold text-gray-800 mb-2 truncate">{@category.name}</h3>
          
          <p class="text-sm text-gray-600 line-clamp-3">{@category.description}</p>
        </div>
        <!-- 하단 화살표 -->
        <div class="flex justify-end pt-4"><.icon name="hero-arrow-right" class="h-5 w-5" /></div>
      </div>
    </.link>
    """
  end

  def handle_event("filter", params, socket) do
    # URL 파라미터를 깔끔하게 정리
    params =
      params
      |> Map.take(~w(q group sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)

    # push_patch는 현재 URL을 변경하고, 페이지를 새로고침하지 않음
    # 이 경우, 현재 LiveView의 상태를 유지하면서 URL만 업데이트
    socket = push_patch(socket, to: ~p"/categories?#{params}")

    {:noreply, socket}
  end
end
