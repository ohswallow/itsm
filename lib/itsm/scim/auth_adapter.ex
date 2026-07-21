defmodule Itsm.Scim.AuthAdapter do
  @behaviour ExScim.Auth.AuthProvider.Adapter

  @impl true
  def validate_bearer(token) do
    case get_by_token(token) do
      %ExScim.Scope{} = api_token ->
        {:ok, api_token}

      _ ->
        {:error, :unauthorized}
    end
  end

  @impl true
  def validate_basic(_username, _password) do
    {:error, :unsupported}
  end

  defp get_by_token(token) when is_binary(token) do
    %ExScim.Scope{id: "id", scopes: ["scim:read", "scim:write"]}
  end

  defp get_by_token(_token) do
    {:error, :no_matched}
  end
end
