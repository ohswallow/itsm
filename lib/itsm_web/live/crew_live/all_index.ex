defmodule ItsmWeb.CrewLive.AllIndex do
  use ItsmWeb, :live_view

  alias Itsm.Crews

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents
  import ItsmWeb.CrewLive.Components

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

  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end
end
