use Mix.Config

# Configure your database
config :serge, Serge.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "serge_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
