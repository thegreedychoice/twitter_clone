# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :user_account,
  ecto_repos: [UserAccount.Repo]

# Configures the endpoint
config :user_account, UserAccount.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "LAB5419CjGGJaYs6uYLHt6YLI3ugfCnxfrG2UB5qv0D7ESb1VJEyGdnEU8t+4Thf",
  render_errors: [view: UserAccount.ErrorView, accepts: ~w(html json)],
  pubsub: [name: UserAccount.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
