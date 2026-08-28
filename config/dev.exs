import Config

# Configure your database
config :itsm, Itsm.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "itsm_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.

config :itsm, ItsmWeb.Endpoint,
  http: [port: "4000"],
  url: [host: "localhost"],
  secret_key_base: "I6wnOim3MX0gWbXK5A5EvCdq5nnt1JLy3+U6aXX2mwri6CVnwkRrtzcAGp0Trs+Q",
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:itsm, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:itsm, ~w(--watch)]}
  ]

# Reload browser tabs when matching files change.
config :itsm, ItsmWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      # Static assets, except user uploads
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
      # Gettext translations
      ~r"priv/gettext/.*\.po$"E,
      # Router, Controllers, LiveViews and LiveComponents
      ~r"lib/itsm_web/router\.ex$"E,
      ~r"lib/itsm_web/(controllers|live|components)/.*\.(ex|heex)$"E
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :itsm, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  # Changing this configuration will require mix clean and a full recompile.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :itsm, Itsm.Workb,
  url: "http://10.138.26.40/HMemoServiceUtf8",
  srv_code: "SQED03",
  sender: "1655201",
  sender_alias: "ITSM"

config :itsm,
  cert_path: "priv/test_saml/sp.crt",
  key_path: "priv/test_saml/sp.key",
  metadata_path: "priv/test_saml/mock-saml-metadata.xml",
  sp_base_url: "http://localhost:4000/sso"

config :itsm,
  kbonecloud_client_id: "MyPX7bX621K2eC575zCK",
  kbonecloud_client_secret: "ekPKm1grpQutbcIEuNHq",
  kbonecloud_introspect_url:
    "https://poc-onepass.kbonecloud.com:8094/mga/sps/oauth/oauth20/introspect"

# PQC, X25519 하이브리드 암호화 키
config :itsm, :meta_crypto_keys,
  pk:
    "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",
  sk: "w7vXrtqT0L/SlQ2KYjmMbgak8i2MGCqnRvp1bn+vlZU="
