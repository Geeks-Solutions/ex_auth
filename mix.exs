defmodule ExAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_auth,
      version: "0.2.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ExAuth.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:phoenix, ">= 1.5.0"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0", only: :test},
      {:phoenix_gen_socket_client,
       git: "https://github.com/J0/phoenix_gen_socket_client.git",
       ref: "9d59e142ff2f51c7a150f4f54c8ae6c3a4ac76df"},
      {:websocket_client, "~> 1.5"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      # {:ex_geeks, path: "/Users/julien/Documents/Repos/Gitlab/Geeks/Libraries/ex_geeks"}
      {:ex_geeks,
       git: "https://github.com/Geeks-Solutions/ex_geeks",
       ref: "9dfc2b93b2be6ac577a6643b230cb354abed7b1d"}
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
      setup: ["deps.get"],
      q: ["format --check-formatted", "compile --warnings-as-errors", "credo --strict"]
    ]
  end
end
