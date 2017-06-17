defmodule Activity.Mixfile do
  use Mix.Project

  def project do
    [
      app: :activity,
      version: "0.11.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :ecto_mnesia,
        :phoenix_html_simplified_helpers,
        :timex_ecto
      ],
      mod: {Activity.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_mnesia, "~> 0.9.0"},
      {:timex, "~> 3.0"}
    ]
  end
end
