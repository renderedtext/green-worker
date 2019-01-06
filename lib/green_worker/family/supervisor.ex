defmodule GreenWorker.Family.Supervisor do
  @moduledoc """
  For each family start:
  - Dynamic-supervisor to supervise workers
  - GenServer to initialize dynamic supervisor on famiy-supervisor start
  """

  use Elixir.Supervisor

  def start_link(gw_module) do
    Supervisor.start_link(__MODULE__, gw_module, name: family_name(gw_module))
  end

  @impl true
  def init(gw_module) do
    worker_supervisor_init_args = [
      gw_module: gw_module,
      config: gw_module.get_config()
    ]

    children = [
      {DynamicSupervisor, name: dynamic_name(gw_module), strategy: :one_for_one},
      {GreenWorker.Family.WorkerSupervisorInit, worker_supervisor_init_args}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def child_spec(args) do
    args
    |> super()
    |> Map.put(:id, args)
  end

  def dynamic_name(gw_module), do: :"#{gw_module}.WorkerSupervisor"

  defp family_name(gw_module), do: :"#{gw_module}.FamilySupervisor"
end
