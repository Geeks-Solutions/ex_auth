defmodule ExAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Application.get_all_env(:ex_auth) |> IO.inspect()
    # Application.loaded_applications()
    # Application.get_env(:ex_auth, :ws_endpoint) |> IO.inspect(label: "HERE")
    # Application.get_env(:auth, :ws_endpoint) |> IO.inspect(label: "me")

    # Application.put_env(
    #   :ex_auth,
    #   :ws_endpoint,
    #   "wss://users-credentials-saas.k8s-dev.geeks.solutions/socket/websocket"
    # )

    # Application.put_env(
    #   :ex_auth,
    #   :endpoint,
    #   "https://users-credentials-saas.k8s-dev.geeks.solutions"
    # )

    children = [
      %{
        id: ExAuth.AuthClient,
        start: {ExAuth.AuthClient, :start_link, []}
      }
      # Start a worker by calling: ExAuth.Worker.start_link(arg)
      # {ExAuth.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(_changed, _new, _removed), do: :ok
end
