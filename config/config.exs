# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :itsm, :scopes,
  user: [
    default: true,
    module: Itsm.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :binary_id,
    schema_table: :users,
    test_data_fixture: Itsm.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :itsm,
  ecto_repos: [Itsm.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :itsm, ItsmWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ItsmWeb.ErrorHTML, json: ItsmWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Itsm.PubSub,
  live_view: [signing_salt: "LTWKZcGV"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :itsm, Itsm.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  itsm: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  itsm: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_scim,
  storage_strategy: Itsm.Scim.StorageAdapter,
  storage_repo: Itsm.Repo,
  user_model: {Itsm.Scim.User, preload: [:groups]},
  group_model: {Itsm.Scim.Group, preload: [:members]},
  auth_provider_adapter: Itsm.Scim.AuthAdapter,
  user_resource_mapper: Itsm.Scim.UsersMapper,
  group_resource_mapper: Itsm.Scim.GroupsMapper

config :ex_saml, ExSaml.Provider,
  idp_id_from: :path_segment,
  service_providers: [
    %{
      id: "itsm_sp",
      entity_id: "urn:itsm:sp",
      certfile: "priv/test_saml/sp.crt",
      keyfile: "priv/test_saml/sp.key"
    }
  ],
  identity_providers: [
    %{
      id: "itsm_idp",
      sp_id: "itsm_sp",
      base_url: "http://localhost:4000/sso",
      metadata_file: "priv/test_saml/mock-saml-metadata.xml",
      nameid_format: :email,
      sign_requests: false,
      sign_metadata: false,
      signed_assertion_in_resp: true,
      signed_envelopes_in_resp: false,
      allow_idp_initiated_flow: true,
      use_redirect_for_req: true,
      use_redirect_for_slo: true,
      allowed_target_urls: [
        "http://localhost:4000/sso"
      ]
    }
  ]

config :ex_saml,
  service_providers_accessor: fn ->
    Application.get_env(:ex_saml, ExSaml.Provider)[:service_providers]
  end,
  identity_providers_accessor: fn ->
    Application.get_env(:ex_saml, ExSaml.Provider)[:identity_providers]
  end

config :ex_saml,
  cache: Itsm.Saml.Cache

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
