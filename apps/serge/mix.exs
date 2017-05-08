defmodule Serge.Mixfile do
  use Mix.Project

  def project do
    [
      app: :serge,
      version: "0.10.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Serge.Application, []},
      extra_applications: [:logger, :runtime_tools, :timex_ecto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:ex_machina, "~> 2.0", only: :test},
      {:ecto, "~> 2.1"},
      {:ecto_enum, "~> 1.0"},
      {:postgrex, ">= 0.0.0"},
      {:secure_random, "~> 0.5.1"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test":       ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
