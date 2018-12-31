use Mix.Config

config :green_worker, ecto_repos: [GreenWorker.EctoRepo]

# config :watchman,
#     host: "statsd",
#     port: 8125,
#     prefix: "green_worker.env-missing"

#
#     import_config "#{Mix.env}.exs"
