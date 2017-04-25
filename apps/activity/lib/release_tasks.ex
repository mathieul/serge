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
    run(fn ->
      IO.puts "Start Mnesia.."
      Mnesia.start()
      config = mnesia_config()

      IO.puts "Create schema.."
      Mnesia.change_table_copy_type(:schema, config[:host], config[:storage_type])
      Mnesia.create_schema([config[:host]])
    end)
  end

  def drop do
    run(fn ->
      IO.puts "Stop Mnesia.."
      Mnesia.stop()

      IO.puts "Ensure dir exists.."
      ensure_mnesia_dir_exists()

      IO.puts "Delete schema.."
      Mnesia.delete_schema([mnesia_config()[:host]])

      IO.puts "Start Mnesia.."
      Mnesia.start()
    end)
  end

  def migrate do
    run(fn -> Enum.each(@myapps, &run_migrations_for/1) end)
  end

  def run(func) do
    IO.puts "Loading myapp.."
    # Load the code for myapp, but don't start it
    :ok = Application.load(:activity)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))

    # Run
    func.()

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

  defp ensure_mnesia_dir_exists() do
    Application.get_env(:mnesia, :dir) |> to_string |> File.mkdir_p!
  end

  defp mnesia_config() do
    [
      host: String.to_atom(System.get_env("MNESIA_HOST")),
      storage_type: String.to_atom(System.get_env("MNESIA_STORAGE_TYPE"))
    ]
  end
end
