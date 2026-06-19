defmodule Itsm.Finalization do
  alias Itsm.Accounts.User
  alias Itsm.Assets

  def execute_after_finish(%User{} = action_user, request) do
    do_execute(request.category.request_name, action_user, request)
  end

  # K리전 공동존 가상머신 생성 완료 시 -> Assets 컨텍스트 호출
  defp do_execute("common_k_create_vm", %User{} = action_user, request) do
    Assets.create_asset_with_os(action_user, request)
  end

  # TODO: category name 기반 나머지 SR들
  defp do_execute(_other_type, _action_user, _request) do
    {:ok, :no_action_needed}
  end
end
