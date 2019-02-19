defmodule GreenWorker.Mixfile do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/renderedtext/green-worker"

  def project do
    [
      app: :green_worker,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger], mod: {GreenWorker.Application, []}]
  end

  defp description do
    """
    DB backed, FSM-like family of workers, distributed on multiple nodes.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Predrag Rakic"],
      licenses: ["Apache License, Version 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "GreenWorker",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp deps do
    [
      {:postgrex, "~> 0.14"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:pubsub, "~> 1.0", only: [:dev, :test]},
      {:uuid, "~> 1.1"},
      {:libcluster, "~> 3.0"},
      {:swarm, "~> 3.3"},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
    ]
  end
end
