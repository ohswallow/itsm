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
