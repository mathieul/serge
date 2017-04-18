use Mix.Config

config :serge, ecto_repos: [Serge.Repo]

import_config "#{Mix.env}.exs"
