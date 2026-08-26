defmodule Itsm.Graphql.Middlewares.Authorize do
  @behaviour Absinthe.Middleware

  def call(%Absinthe.Resolution{} = resolution, required_roles) do
    current_scope = resolution.context.current_scope

    case verify_user_role(current_scope.role_names, required_roles) do
      :ok ->
        resolution

      {:error, message} ->
        Absinthe.Resolution.put_result(resolution, {:error, message})
    end
  end

  defp verify_user_role(nil, _roles), do: {:error, "인증되지 않은 사용자입니다. 로그인 후 요청해주세요."}

  defp verify_user_role(role_names, roles) do
    if roles == [] or Enum.any?(roles, &(&1 in role_names)) do
      :ok
    else
      {:error, "권한이 부족합니다. 추가 권한을 요청해주세요."}
    end
  end
end
