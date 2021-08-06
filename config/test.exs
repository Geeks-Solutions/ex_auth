use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_auth, ExAuthWeb.Endpoint,
  http: [port: 4002],
  server: true

config :ex_auth,
  endpoint: "http://localhost:4002/mock/auth",
  ws_endpoint: "ws://localhost:5530",
  project_id: "1",
  private_key: "private_key"

# Print only warnings and errors during test
config :logger, level: :warn
