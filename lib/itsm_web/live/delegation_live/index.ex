defmodule ItsmWeb.DelegationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Delegations
  alias Itsm.Delegations.Delegation

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delegations.subscribe_delegation_list()
    end

    # 접속 user 부서에 해당하는 대결등록만 로드
    {:ok, stream(socket, :delegations, Delegations.list_delegations(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Delegation"))
    # |> assign(:page_title, "New Delegation")
    |> assign(:delegation, %Delegation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Delegations"))
    |> assign(:delegation, nil)
  end

  # Delegation이 저장되었을 때 스트림에 추가
  @impl true
  def handle_info({ItsmWeb.DelegationLive.FormComponent, {:saved, delegation}}, socket) do
    {:noreply, stream_insert(socket, :delegations, delegation)}
  end

  # 대결등록 새로 생성되었을 때 리스트를 새로고침
  def handle_info({:delegation_created, _}, socket) do
    {:noreply,
     socket
     |> stream(:delegations, Delegations.list_delegations(socket.assigns.current_user),
       reset: true
     )}
  end

  # 대결등록 삭제되었을 때 리스트를 새로고침
  def handle_info({:delegation_deleted, _}, socket) do
    {:noreply,
     socket
     |> stream(:delegations, Delegations.list_delegations(socket.assigns.current_user),
       reset: true
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    delegation = Delegations.get_delegation!(id)
    current_user = socket.assigns.current_user

    case Delegations.delete_delegation(delegation, current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:delegations, delegation)
         |> put_flash(:info, gettext("Delegation deleted successfully."))}

      # 권한 없는 사용자가 삭제 시도할 때
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Only the creator can delete this delegation."))}

      # 기타 오류 처리
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("An unknown error occurred."))}
    end
  end
end
