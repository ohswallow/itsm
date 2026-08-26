defmodule Itsm.MixProject do
  use Mix.Project

  def project do
    [
      app: :itsm,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Itsm.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "== 1.11.0"},
      {:absinthe_phoenix, "== 2.0.5"},
      {:absinthe_plug, "== 1.5.10"},
      {:bandit, "== 1.12.0"},
      {:cc_precompiler, "== 0.1.11"},
      {:comeonin, "== 5.5.1"},
      {:db_connection, "== 2.10.1"},
      {:decimal, "== 3.1.1"},
      {:dns_cluster, "== 0.2.0"},
      {:ecto, "== 3.14.0"},
      {:ecto_psql_extras, "== 0.8.8"},
      {:ecto_sql, "== 3.14.0"},
      {:elixir_make, "== 0.9.0"},
      {:elixir_uuid, "== 1.2.1"},
      {:esbuild, "== 0.10.0", runtime: Mix.env() == :dev},
      {:ex_saml, "== 1.1.2"},
      {:ex_scim, "== 0.1.0"},
      {:ex_scim_ecto, "== 0.1.0"},
      {:ex_scim_phoenix, "== 0.1.0"},
      {:expo, "== 1.1.1"},
      {:file_system, "== 1.1.1"},
      {:finch, "== 0.23.0"},
      {:fine, "== 0.1.6"},
      {:gettext, "== 1.0.2"},
      {:hpax, "== 1.0.4"},
      {:idna, "== 7.1.0"},
      {:jason, "== 1.4.5"},
      {:lazy_html, "== 0.1.11", only: :test},
      {:live_select, "== 1.7.5"},
      {:logger_file_backend, "== 0.0.14"},
      {:metamorphic_crypto, "== 0.3.0"},
      {:mime, "== 2.0.7"},
      {:mint, "== 1.9.3"},
      {:nebulex, "== 2.6.6"},
      {:nimble_options, "== 1.1.1"},
      {:nimble_parsec, "== 1.4.2"},
      {:nimble_pool, "== 1.1.0"},
      {:pbkdf2_elixir, "== 2.3.1"},
      {:phoenix, "== 1.8.9"},
      {:phoenix_ecto, "== 4.7.0"},
      {:phoenix_html, "== 4.3.0"},
      {:phoenix_html_helpers, "== 1.0.1"},
      {:phoenix_live_dashboard, "== 0.8.7"},
      {:phoenix_live_reload, "== 1.6.2", only: :dev},
      {:phoenix_live_view, "== 1.2.7"},
      {:phoenix_pubsub, "== 2.2.0"},
      {:phoenix_template, "== 1.0.4"},
      {:plug, "== 1.20.3"},
      {:plug_crypto, "== 2.1.1"},
      {:postgrex, "== 0.22.3"},
      {:ranch, "== 2.2.0"},
      {:req, "== 0.6.3"},
      {:rustler, "== 0.37.3"},
      {:rustler_precompiled, "== 0.9.0"},
      {:sweet_xml, "== 0.7.5"},
      {:swoosh, "== 1.26.3"},
      {:table_rex, "== 4.1.0"},
      {:tailwind, "== 0.5.0", runtime: Mix.env() == :dev},
      {:telemetry, "== 1.4.2"},
      {:telemetry_metrics, "== 1.1.0"},
      {:telemetry_poller, "== 1.3.0"},
      {:thousand_island, "== 1.5.0"},
      {:websock, "== 0.5.3"},
      {:websock_adapter, "== 0.5.9"},
      {:daisyui, path: "deps/daisyui", app: false, compile: false},
      {:heroicons, path: "deps/heroicons", app: false, compile: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind itsm", "esbuild itsm"],
      "assets.deploy": [
        "tailwind itsm --minify",
        "esbuild itsm --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
