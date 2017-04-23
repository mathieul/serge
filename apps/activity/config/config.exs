use Mix.Config

mnesia_priv_path = "priv/data/mnesia_#{Mix.env}"
mnesia_path = Path.join(File.cwd!(), mnesia_priv_path)

unless File.exists?(mnesia_path), do: File.mkdir_p!(mnesia_path)

config :mnesia,
  dir: to_charlist(mnesia_path)

config :activity, Activity.Repo,
  adapter: EctoMnesia.Adapter

config :ecto_mnesia,
  host: {:system, :atom, "MNESIA_HOST", Kernel.node()},
  storage_type: {:system, :atom, "MNESIA_STORAGE_TYPE", :disc_copies}

config :activity,
  ecto_repos: [Activity.Repo]
