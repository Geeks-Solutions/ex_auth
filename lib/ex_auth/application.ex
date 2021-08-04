defmodule ExAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExAuthWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExAuth.PubSub},
      # Start the Endpoint (http/https)
      ExAuthWeb.Endpoint
      # Start a worker by calling: ExAuth.Worker.start_link(arg)
      # {ExAuth.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExAuthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
