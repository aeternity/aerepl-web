use Mix.Config

# Configure your database
config :aerepl_http, AereplHttp.Repo,
  username: "postgres",
  password: "postgres",
  database: "aerepl_http_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aerepl_http, AereplHttpWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
