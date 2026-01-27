defmodule ItsmWeb.TeamLive.AllIndex do
  use ItsmWeb, :live_view

  alias Itsm.Crews
  alias Itsm.Accounts

  # 공통 컴포넌트 임포트
  import ItsmWeb.TeamLive.TableComponents

  def mount(_params, _session, socket) do
    # socket = assign(socket, :categories, Service.list_categories())
    # IO.inspect(self(), label: "MOUNT")
    org_options = Accounts.list_organization_options()
    {:ok, socket |> assign(:org_options, org_options)}
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
    <.form
      for={@form}
      class="sm:flex justify-center gap-4 items-cente mt-2"
      id="filter-form"
      phx-change="filter"
    >
      <.input field={@form[:keyword]} placeholder="Search..." autocomplete="off" phx-debounce="300" />
      <%!-- <.input
        type="select"
        field={@form[:organization]}
        prompt="Organization"
        options={["KB국민은행", "KB국민카드", "KB캐피탈", "KB증권"]}
      />  --%>
      <.input
        type="select"
        field={@form[:organization_code]}
        prompt="Organization"
        options={@org_options}
      /> <%!-- navigate 대신 patch를 사용하여 URL을 변경 --%>
      <.link patch={~p"/crews/all"} class="flex items-center hover:underline">Reset</.link>
    </.form>
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
