# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :ex_auth, ExAuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "XCgU0FfGU0iRYa+osyBQGnp5+yWW1nblmmQRggSZmAICvyjwNCg7si0RMde/Q1en",
  render_errors: [view: ExAuthWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ExAuth.PubSub,
  live_view: [signing_salt: "NiiZs5Ru"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# config :auth,
#   endpoint: "https://users-credentials-saas.k8s-dev.geeks.solutions",
#   ## websocket_endpoint
#   ws_endpoint: "wss://users-credentials-saas.k8s-dev.geeks.solutions/socket/websocket"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
