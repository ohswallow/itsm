defmodule Itsm.Scim.AuthAdapter do
  @behaviour ExScim.Auth.AuthProvider.Adapter

  @impl true
  def validate_bearer(token) do
    case introspect(token) do
      {:ok, _} = result ->
        result

      _ ->
        {:error, :unauthorized}
    end
  end

  @impl true
  def validate_basic(_username, _password) do
    {:error, :unsupported}
  end

  def introspect(access_token) when is_binary(access_token) do
    case request_validate_token(access_token) do
      {:ok, %Req.Response{status: 200, body: %{"active" => true} = body}} ->
        user =
          Itsm.Accounts.get_user_by_employee_number(body.username) |> Itsm.Repo.preload(:roles)

        scopes =
          if Enum.any?(user.roles, &(&1.name == "admin")),
            do: ["scim:read", "scim:write"],
            else: []

        scope = %ExScim.Scope{id: body.username, scopes: scopes}
        {:ok, scope}

      {:ok, %Req.Response{status: 200, body: %{"active" => false} = body}} ->
        {:error, :inactive_token, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status}, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp request_validate_token(access_token) do
    client_id = Application.get_env(:itsm, :kbonecloud_client_id)
    client_secret = Application.get_env(:itsm, :kbonecloud_client_secret)
    url = Application.get_env(:itsm, :kbonecloud_introspect_url)

    request_opts = [
      auth: {:basic, "#{client_id}:#{client_secret}"},
      form: [token: access_token],
      decode_body: true
    ]

    Req.post(url, request_opts)
  end
end
