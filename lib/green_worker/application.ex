defmodule GreenWorker.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GreenWorker.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  if Mix.env() == :test do
    defp children do
      [
        Support.EctoRepo
      ]
    end
  else
    defp children do
      []
    end
  end
end
