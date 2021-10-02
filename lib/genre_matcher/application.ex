defmodule GenreMatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      GenreMatcher.Repo,
      # Start the Telemetry supervisor
      GenreMatcherWeb.Telemetry,
      # Redix Process
      {Redix, host: "localhost", port: 6969, name: :redix},
      # Start the PubSub system
      {Phoenix.PubSub, name: GenreMatcher.PubSub},
      # Start the Endpoint (http/https)
      GenreMatcherWeb.Endpoint
      # Start a worker by calling: GenreMatcher.Worker.start_link(arg)
      # {GenreMatcher.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GenreMatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GenreMatcherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
