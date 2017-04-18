use Mix.Config

# Configure your database
config :serge, Serge.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "serge_dev",
  hostname: "localhost",
  pool_size: 10
