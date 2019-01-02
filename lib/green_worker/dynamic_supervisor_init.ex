defmodule GreenWorker.DynamicSupervisorInit do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts = [gw_module: gw_module, config: config]) do
    opts
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_name")

    start_all_non_finished_workers(gw_module, config)
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ all w")

    {:ok, opts}
  end

  @doc """
  Starts all workers that are not in "done" state.
  """
  def start_all_non_finished_workers(gw_module, config) do
    gw_module
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_module")

    GreenWorker.Queries.get_all_non_finished_workers(config.schema, config.repo)
    |> Enum.map(fn ctx -> GreenWorker.start_supervised(gw_module, Map.get(ctx, config.key)) end)
  end
end
