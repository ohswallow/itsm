defmodule ItsmWeb.LiveUtils do
  @moduledoc """
  ITSM 개발에 필요한 Util메소드 정의 합니다.
  """
  def change_assignee_name(%Phoenix.LiveView.Socket{} = socket, %Itsm.Accounts.User{} = assignee) do
    Map.merge(socket.assigns.form.params, %{"assignee_name" => assignee.display_name})
  end
end
