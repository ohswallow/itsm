defmodule Itsm.Graphql.Middlewares.Authorize do
  @behaviour Absinthe.Middleware

  def call(%Absinthe.Resolution{} = resolution, required_roles) do
    current_user = resolution.context.current_scope.user

    case verify_user_role(current_user, required_roles) do
      :ok ->
        resolution

      {:error, message} ->
        Absinthe.Resolution.put_result(resolution, {:error, message})
    end
  end

  defp verify_user_role(nil, _roles), do: {:error, "인증되지 않은 사용자입니다. 로그인 후 요청해주세요."}

  defp verify_user_role(user, roles) do
    if roles == [] or user.role in roles do
      :ok
    else
      {:error, "#{user.role} 권한으로는 부족합니다. 추가 권한을 요청해주세요."}
    end
  end
end
