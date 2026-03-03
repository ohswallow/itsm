defmodule Itsm.Finalization do
  alias Itsm.Assets

  def execute_after_finish(request) do
    do_execute(request.category.request_name, request)
  end

  # K리전 공동존 가상머신 생성 완료 시 -> Assets 컨텍스트 호출
  defp do_execute("common_k_create_vm", request) do
    Assets.create_asset_with_os(request)
  end

  # TODO: category name 기반 나머지 SR들
  defp do_execute(_other_type, _request) do
    {:ok, :no_action_needed}
  end
end
