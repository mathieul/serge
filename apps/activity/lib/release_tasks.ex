defmodule Activity.ReleaseTasks do
  alias :mnesia, as: Mnesia

  @start_apps [
    :mnesia,
    :ecto
  ]

  @myapps [
    :activity
  ]

  @repos [
    Activity.Repo
  ]

  def create do
    Mnesia.start()
    config = mnesia_config()
    Mnesia.change_table_copy_type(:schema, config[:host], config[:storage_type])
    Mnesia.create_schema([config[:host]])
  end

  def drop do
    Mnesia.stop()
    ensure_mnesia_dir_exists()
    Mnesia.delete_schema([mnesia_config()[:host]])
    Mnesia.start()
  end

  def seed do
    IO.puts "Loading myapp.."
    # Load the code for myapp, but don't start it
    :ok = Application.load(:activity)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))

    # Run migrations
    Enum.each(@myapps, &run_migrations_for/1)

    # Run the seed script if it exists
    seed_script = Path.join([priv_dir(:activity), "repo", "seeds.exs"])
    if File.exists?(seed_script) do
      IO.puts "Running seed script.."
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(Activity.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
  defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])

  defp ensure_mnesia_dir_exists() do
    Application.get_env(:mnesia, :dir) |> to_string |> File.mkdir_p!
  end

  defp mnesia_config() do
    [
      host: System.get_env("MNESIA_HOST"),
      storage_type: System.get_env("MNESIA_STORAGE_TYPE")
    ]
  end
end
