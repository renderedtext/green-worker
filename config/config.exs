use Mix.Config

# Needed for tests.
config :green_worker, ecto_repos: [Support.EctoRepo]

config :swarm,
  # Needed for tests to start immediately.
  sync_nodes_timeout: 0

# config :watchman,
#     host: "statsd",
#     port: 8125,
#     prefix: "green_worker.env-missing"

#
#     import_config "#{Mix.env}.exs"
