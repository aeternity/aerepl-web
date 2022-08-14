# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :aerepl_http,
  ecto_repos: [AereplHttp.Repo]

# Configures the endpoint
config :aerepl_http, AereplHttpWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jQFd/4mPbDamT7HtZAFPaqCPvQuWNCLys/K4Pkk4d/1pst/cre5TstsGAEQ81Xru",
  render_errors: [view: AereplHttpWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: AereplHttp.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "oWsPn6IQ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :aecore,
  persist: false,
  network_id: <<"local_lima_testnet">>

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
