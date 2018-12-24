defmodule GreenWorker.DynamicSupervisorInit do

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts = [gw_module: gw_module, schema: schema, repo: repo]) do
    opts
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_name")

    start_all_non_finished_workers(gw_module, schema, repo)
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ all w")

    {:ok, opts}
  end

  @doc """
  Starts all workers that are not in "done" state.
  """
  def start_all_non_finished_workers(gw_module, schema, repo) do
    gw_module
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_module")

    GreenWorker.get_all_non_finished_workers(schema, repo)
    |> Enum.map(fn ctx -> GreenWorker.start_supervised(gw_module, ctx.id) end)
  end

end
