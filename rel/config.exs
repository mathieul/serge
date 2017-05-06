# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :combined,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"X,9BCTYRySd3AiIn&[NF&%YN<$/Q;^wM02>^n12|%;!NzO3WLiTmzS^P)SsCOHB!"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"x^C)d,VIsPW;2cnzWC7~hV0BY7k4Y|BIJR9qu%?.mc|BLJRwBCv>VJ(FLyybWw3("
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :combined do
  set version: "0.10.0"
  set applications: [
    :runtime_tools,
    activity: :permanent,
    serge: :permanent,
    serge_web: :permanent
  ]
  set commands: [
    "migrate": "rel/commands/migrate.sh",
    "create_activity": "rel/commands/create_activity.sh",
    "drop_activity": "rel/commands/drop_activity.sh",
  ]
end

release :serge do
  set version: current_version(:serge)
end

release :activity do
  set version: current_version(:activity)
end

release :serge_web do
  set version: current_version(:serge_web)
end
