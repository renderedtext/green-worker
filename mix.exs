# Generated by usvc-1.15.0
# Feel free to adjust, it will not be overridden

defmodule GreenWorker.Mixfile do
  use Mix.Project

  def project do
    [app: :green_worker,
     version: "0.2.0",
     elixir: "~> 1.6",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger],
     mod: {GreenWorker.Application, []}]
  end

  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:postgrex, "~> 0.14"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:pubsub, "~> 1.0", only: [:dev, :test]},
      {:uuid, "~> 1.1"},
      {:libcluster, "~> 3.0"},
      {:swarm, "~> 3.3"},
    ]
  end
end
