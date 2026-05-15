defmodule ItsmWeb.DelegationLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Delegations
  alias Itsm.Delegations.Delegation
  alias Itsm.Accounts.User

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:delegations, []) |> Itsm.PubSub.Helper.subscribe(Delegations)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("delete", %{"id" => _id} = delegation_params, socket) do
    %{current_user: action_user} = socket.assigns

    case Delegations.delete_delegation(action_user, delegation_params) do
      {:ok, delegation} ->
        {:noreply, stream_delete(socket, :delegations, delegation)}

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

  # Delegation이 저장되었을 때 스트림에 추가
  def handle_info({ItsmWeb.DelegationLive.FormComponent, {:saved, delegation}}, socket) do
    {:noreply, stream_insert(socket, :delegations, delegation)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Delegation"))
    |> assign(:delegation, %Delegation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Delegations"))
    |> stream(:delegations, Delegations.list_delegations(socket.assigns.current_user),
      reset: true
    )
  end

  # 삭제 권한이 있는지 확인하는 헬퍼 함수
  # 1. 관리자(admin)라면 무조건 true
  defp can_delete?(%User{role: "admin"}, _delegation), do: true

  # 2. 일반 유저라도 본인이 만든(created_by_id 일치) 위임이라면 true
  defp can_delete?(%User{id: user_id}, %Delegation{created_by_id: created_by_id})
       when user_id == created_by_id,
       do: true

  # 3. 그 외에는 모두 false (버튼 숨김)
  defp can_delete?(_user, _delegation), do: false

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :delegation,
      resource_name: gettext("Delegation"),
      stream_name: :delegations,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
