# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :twitter_server,
  ecto_repos: [TwitterServer.Repo]

# Configures the endpoint
config :twitter_server, TwitterServer.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+XsNHy5ZUo0ZpsJtdBuSn22wRVEVtD5OPET1pLBWe9uNri+7981GgpmpmZN/ElUu",
  render_errors: [view: TwitterServer.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterServer.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
