defmodule Serge.Web.Mixfile do
  use Mix.Project

  def project do
    [
      app: :serge_web,
      version: "0.10.2",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Serge.Web.Application, []},
      extra_applications: [:bamboo, :logger, :runtime_tools, :elixir_make, :timex_ecto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:absinthe_plug, "~> 1.3.0"},
      {:absinthe, "~> 1.3.0"},
      {:activity, in_umbrella: true},
      {:bamboo, "~> 1.0.0-rc.1"},
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.1.2"},
      {:gettext, "~> 0.13.1"},
      {:oauth2, "~> 0.9"},
      {:phoenix_active_link, "~> 0.1.1"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.9.3"},
      {:phoenix_html_simplified_helpers, "~> 1.1"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix, "~> 1.3-rc.1"},
      {:serge, in_umbrella: true},
      {:timex, "~> 3.0"}
    ]
  end

  defp aliases do
    [
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
