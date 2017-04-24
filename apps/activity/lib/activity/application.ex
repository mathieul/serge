defmodule Activity.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Activity.Repo, [])
    ]
    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: Activity.Supervisor)
  end
end
