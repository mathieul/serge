# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :serge_web,
  namespace: Serge.Web,
  ecto_repos: [Serge.Repo]

# Configures the endpoint
config :serge_web, Serge.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tlV9yDTRhI5DHnGhKVpzBQKmruikJHsbqFtviWFkVwi65Xdc7LGOoFiwbwVmUWdl",
  render_errors: [view: Serge.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Serge.Web.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# config/config.exs
config :oauth2,
  serializers: %{
    "application/vnd.api+json" => Poison,
    "application/json" => Poison,
    "application/xml" => MyApp.XmlParser,
  }

config :serge_web, Serge.Web.Oauth.GitHub,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
  redirect_uri: System.get_env("GITHUB_REDIRECT_URI")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
