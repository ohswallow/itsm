defmodule Itsm.Saml.Provider do
  def get_service_provider do
    [
      %{
        id: "onepass-sp",
        entity_id: "kbbank-sqe-itsm",
        certfile: config(:cert_path),
        keyfile: config(:key_path)
      }
    ]
  end

  def get_identity_provider do
    [
      %{
        id: "onepass",
        sp_id: "onepass-sp",
        base_url: config(:sp_base_url),
        metadata_file: config(:metadata_path),
        nameid_format: :email,
        sign_requests: false,
        sign_metadata: false,
        signed_assertion_in_resp: true,
        signed_envelopes_in_resp: false,
        allow_idp_initiated_flow: true,
        use_redirect_for_req: true,
        use_redirect_for_slo: true,
        allowed_target_urls: [config(:sp_base_url)]
      }
    ]
  end

  defp config(key) do
    Application.get_env(:itsm, key)
  end
end
