defmodule GreenWorker.Family.WorkerSupervisorInit do
  use GenServer

  alias GreenWorker.Queries

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  @doc """
  Starts workers for all `schema` entries in `repo`
  that are not in "terminal state".

  Required `opts`:
  - `gw_module` - GreenWorker module name
  - `config` - options specified when worker was defined
  """
  def init(opts = [gw_module: gw_module, config: config]) do
    opts
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_name")

    start_all_non_finished_workers(gw_module, config)
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ all w")

    {:ok, opts}
  end

  @doc """
  Starts all workers that are not in terminal state.
  """
  def start_all_non_finished_workers(gw_module, config) do
    gw_module
    |> IO.inspect(label: "ZZZZZZZZZZZZZZ gw_module")

    Queries.get_all_non_finished_workers(
      config.schema,
      config.repo,
      config.state_field_name,
      config.terminal_states
    )
    |> Enum.map(fn ctx ->
      GreenWorker.start_supervised(gw_module, Map.get(ctx, config.key_field_name))
    end)
  end
end
