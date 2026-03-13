defmodule ItsmWeb.CrewLive.AllIndex do
  use ItsmWeb, :live_view

  alias Itsm.Crews

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents

  def mount(_params, _session, socket) do
    if(connected?(socket)) do
      Crews.subscribe_crews()
    end

    {:ok, socket |> assign(:org_options, Itsm.CommonCodes.get_select_options("계열사"))}
  end

  def handle_params(params, _uri, socket) do
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

  def handle_info({:crews, {:delete_crew, crew}}, socket) do
    {:noreply, stream_delete(socket, :crews, crew)}
  end

  def handle_info({:crews, {event, _crew}}, socket) when event in [:create_crew, :update_crew] do
    %{filter_params: params} = socket.assigns

    {:noreply, push_patch(socket, to: ~p"/crews/all?#{params}")}
  end

  def handle_info(_event, socket), do: {:noreply, socket}

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
end
