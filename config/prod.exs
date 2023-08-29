import Mix.Config

config :aerepl_web, AereplServerWeb.Endpoint,
  server: true,
  url: [host: "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

import_config "prod.secret.exs"
