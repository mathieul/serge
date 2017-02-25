defmodule Serge.Mixfile do
  use Mix.Project

  def project do
    [
      app: :serge,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Serge, []},
      applications: [
        :absinthe_plug,
        :absinthe,
        :cowboy,
        :gettext,
        :logger,
        :oauth2,
        :phoenix_ecto,
        :phoenix_html,
        :phoenix_pubsub,
        :phoenix,
        :postgrex,
        :timex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe_plug, "~> 1.2.2"},
      {:absinthe, "~> 1.2.1"},
      {:comeonin, "~> 3.0"},
      {:cowboy, "~> 1.1.2"},
      {:ecto_ordered, "~> 0.2.0-beta1"},
      {:exrm, "~> 1.0.8"},
      {:gettext, "~> 0.13.1"},
      {:oauth2, "~> 0.9"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.9.3"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix, "~> 1.2.1"},
      {:postgrex, ">= 0.0.0"},
      {:timex, "~> 3.0"}
   ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
