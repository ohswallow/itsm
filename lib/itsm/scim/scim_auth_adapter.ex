defmodule Itsm.Scim.ScimAuthAdapter do
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
    case Req.post("https://example.com/oauth/token",
           form: %{
             client_id: "your_client_id",
             client_secret: "your_client_secret",
             token: "fa..."
           }
         ) do
      {:ok, %Req.Response{status: 200, body: _body}} ->
        %ExScim.Scope{id: "id", scopes: ["scim:read", "scim:write"]}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:unexpected_status, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_by_token(_token) do
    {:error, :no_matched}
  end
end
