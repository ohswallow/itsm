defmodule Itsm.Repo do
  use Ecto.Repo,
    otp_app: :itsm,
    adapter: Ecto.Adapters.Postgres
end
