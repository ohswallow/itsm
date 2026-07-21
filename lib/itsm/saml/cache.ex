defmodule Itsm.Saml.Cache do
  use Nebulex.Cache,
    otp_app: :itsm,
    adapter: Nebulex.Adapters.Local
end
