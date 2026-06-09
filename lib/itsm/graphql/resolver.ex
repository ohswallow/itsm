defmodule Itsm.Graphql.Resolver do
  alias Itsm.Posts

  def list_posts(_parent, _args, %Absinthe.Resolution{} = resolution) do
    resolution
    |> check_auth()
    |> case do
      {:ok, _role} -> {:ok, Posts.list_posts()}
      {:error, message} -> {:error, message}
    end
  end

  def get_post!(_parent, args, %Absinthe.Resolution{} = resolution) do
    resolution
    |> check_auth()
    |> case do
      {:ok, _role} -> {:ok, Posts.get_post!(args)}
      {:error, message} -> {:error, message}
    end
  end

  defp check_auth(%Absinthe.Resolution{} = resolution) do
    required_roles =
      Map.get(resolution, :meta, %{})
      |> Map.get(:required_role, [])

    current_user = resolution.context[:current_user]
    verify_user_role(current_user, required_roles)
  end

  defp verify_user_role(nil, _required_roles) do
    {:error, "인증되지 않은 사용자입니다. 로그인 후 요청해주세요."}
  end

  defp verify_user_role(%Itsm.Accounts.User{role: role}, required_roles) do
    if required_roles == [] or role in required_roles do
      {:ok, role}
    else
      {:error, "#{role} 권한으로는 부족합니다. 추가 권한을 요청해주세요."}
    end
  end
end
