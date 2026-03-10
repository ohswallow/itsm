defmodule ItsmWeb.CrewLive.AllIndex do
  use ItsmWeb, :live_view

  alias Itsm.Crews

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents

  def mount(_params, _session, socket) do
    # socket = assign(socket, :categories, Service.list_categories())
    # IO.inspect(self(), label: "MOUNT")
    {:ok, socket |> assign(:org_options, Itsm.CommonCodes.get_select_options("계열사"))}
  end

  def handle_params(params, _uri, socket) do
    # IO.inspect(self(), label: "HANDLE_PARAMS")

    # 1. URL에 지저분한 파라미터가 섞이지 않도록 필요한 필터만
    filter_params = Map.take(params, ["keyword", "organization_code"])

    socket =
      socket
      |> assign(:page_title, "All Crew")
      |> stream(:crews, Crews.filter_crews(params), reset: true)
      |> assign(:form, to_form(params))
      # 2 현재 필터 조건을 뷰에서 쓸 수 있게 assign
      |> assign(:filter_params, filter_params)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>{@page_title}</.header>
     <.filter_form form={@form} org_options={@org_options} />
    <.crew_table
      crews={@streams.crews}
      row_click={
        fn {_id, crew} ->
          # 3. 돌아올 URL을 미리 만듦 (필터가 포함된 URL)
          # 예: "/crews/all?q=AAA&organization=KB국민은행"
          return_url = ~p"/crews/all?#{@filter_params}"

          # 4. return_to 파라미터에 위에서 만든 URL을 통째로 넘김
          JS.navigate(~p"/crews/#{crew}?return_to=#{return_url}")
        end
      }
    >
    </.crew_table>
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
          <.input
            field={@form[:keyword]}
            placeholder="Search..."
            autocomplete="off"
            phx-debounce="300"
          />
        </div>
        
        <div class="md:col-span-3">
          <.input
            type="select"
            field={@form[:organization_code]}
            prompt="계열사"
            options={@org_options}
          />
        </div>
        
        <div class="md:col-span-2 flex justify-end pb-1">
          <.link
            patch={~p"/crews/all"}
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

  def handle_event("filter", params, socket) do
    # URL 파라미터를 깔끔하게 정리
    params =
      params
      |> Map.take(~w(keyword organization_code))
      |> Map.reject(fn {_, v} -> v == "" end)

    # push_patch는 현재 URL을 변경하고, 페이지를 새로고침하지 않음
    # 이 경우, 현재 LiveView의 상태를 유지하면서 URL만 업데이트
    socket = push_patch(socket, to: ~p"/crews/all?#{params}")

    {:noreply, socket}
  end
end
