defmodule Itsm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ItsmWeb.Telemetry,
      Itsm.Repo,
      {DNSCluster, query: Application.get_env(:itsm, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Itsm.PubSub},
      # Start a worker by calling: Itsm.Worker.start_link(arg)
      # {Itsm.Worker, arg},
      # Start to serve requests, typically the last entry
      ItsmWeb.Endpoint,
      Itsm.CommonCodeCache,
      {Task.Supervisor, name: Itsm.TaskSupervisor},
      ExSaml.Provider,
      Itsm.Saml.Cache,
      {Finch, name: Itsm.Finch}
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options

    :telemetry.attach(
      "audit-logger",
      [:itsm, :repo, :query],
      &Itsm.AuditLogger.handle_event/4,
      nil
    )

    opts = [strategy: :one_for_one, name: Itsm.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ItsmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
