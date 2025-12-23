defmodule ItsmWeb.TeamLive.AllIndex do
  use ItsmWeb, :live_view

  alias Itsm.Team
  # alias Itsm.Team.Crew
  # 공통 컴포넌트 임포트
  import ItsmWeb.TeamLive.TableComponents

  def mount(_params, _session, socket) do
    # socket = assign(socket, :categories, Service.list_categories())
    # IO.inspect(self(), label: "MOUNT")
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    # IO.inspect(self(), label: "HANDLE_PARAMS")

    socket =
      socket
      |> assign(:page_title, "All Crew")
      |> stream(:crews, Team.filter_crews(params), reset: true)
      |> assign(:form, to_form(params))

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>{@page_title}</.header>
     <.filter_form form={@form} />
    <.crew_table
      crews={@streams.crews}
      row_click={
        fn {_id, crew} ->
          JS.navigate(~p"/crews/#{crew}?return_to=all")
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
      <.input field={@form[:q]} placeholder="Search..." autocomplete="off" phx-debounce="500" />
      <.input
        type="select"
        field={@form[:organization]}
        prompt="Organization"
        options={["KB국민은행", "KB국민카드", "KB캐피탈", "KB증권"]}
      /> <%!-- navigate 대신 patch를 사용하여 URL을 변경 --%>
      <.link patch={~p"/crews/all"} class="flex items-center hover:underline">Reset</.link>
    </.form>
    """
  end

  def handle_event("filter", params, socket) do
    # URL 파라미터를 깔끔하게 정리
    params =
      params
      |> Map.take(~w(q organization))
      |> Map.reject(fn {_, v} -> v == "" end)

    # push_patch는 현재 URL을 변경하고, 페이지를 새로고침하지 않음
    # 이 경우, 현재 LiveView의 상태를 유지하면서 URL만 업데이트
    socket = push_patch(socket, to: ~p"/crews/all?#{params}")

    {:noreply, socket}
  end
end
