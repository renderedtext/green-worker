defmodule GreenWorker do
  @moduledoc """
  Documentation for GreenWorker.
  """

  alias GreenWorker.Util

  defmodule Behaviour do
    @moduledoc false

    @callback context_handler(Map.t) :: Ecto.Query.t()
  end

  defmacro __using__(opts) do
    # Module name representing Ecto schema to load/store context
    schema            = Util.get_mandatory_field(opts, :schema)
    # Module name representingEecto repo
    repo              = Util.get_mandatory_field(opts, :repo)
    # Expects `{M,F}` tuple; default `nil`
    # If not nil calls `M.F/2`
    changeset         = Util.get_optional_field(opts, :changeset)

    quote do
      @behaviour GreenWorker.Behaviour

      use GenServer

      def start_link(id) do
        GenServer.start_link(__MODULE__, id, name: name(id))
      end

      def get_context(id) do
        GenServer.call(name(id), :get_context)
      end

      def handle_context(id) do
        GenServer.cast(name(id), :handle_context)
      end

      @impl true
      def init(id) do
        ctx = GreenWorker.load_context(id, unquote(schema), unquote(repo))
        |>IO.inspect(label: "QQQQQQQQQQQQQQQQ")
        |> case do
          nil ->
            {:id_not_found, id}
          ctx ->
            handle_context(id)

            {:ok, ctx}
        end
      end

      @impl true
      def handle_call(:get_context, _from, ctx) do
        {:reply, ctx, ctx}
      end

      @impl true
      def handle_cast(:handle_context, ctx) do
        new_ctx = context_handler(ctx)

        if new_ctx != ctx do
          handle_context(ctx.id)

          {:ok, _} = GreenWorker.store_context(ctx, new_ctx, unquote(changeset), unquote(repo))
        end

        {:noreply, new_ctx}
      end

      defp name(id), do: :"#{__MODULE__}_#{id}"

      ##### Supervisor

      # This alias is available to sub-module Supervisor (lexical scoping)
      alias __MODULE__, as: ContainingModule

      defmodule Supervisor do

        use Elixir.Supervisor

        def start_link(gw_name) do
         Supervisor.start_link(__MODULE__, gw_name)
        end

        @impl true
        def init(gw_name) do
          dynamic_supervisor_init_args = [
            gw_module: ContainingModule,
            schema: unquote(schema),
            repo: unquote(repo)
          ]

          children = [
            {DynamicSupervisor, name: __MODULE__, strategy: :one_for_one},
            {GreenWorker.DynamicSupervisorInit, dynamic_supervisor_init_args}
          ]

          Supervisor.init(children, strategy: :rest_for_one)
        end
      end

    end
  end

  @doc """
  Start GreenWorker process under dynamic supervisor

  ## Example

      {:ok, pid} = start_supervised(WorkerModule, "worker_unique_id")
  """
  def start_supervised(module, id) when is_binary(id) do
    DynamicSupervisor.start_child(supervisor_name(module), {module, id})
  end

  def load_context(id, schema, repo) do
    repo.get(schema, id)
  end

  def store_context(ctx, new_ctx, changeset, repo) do
    case changeset do
      nil -> new_ctx

      {m, f} -> apply(m, f, [ctx, to_map(new_ctx)])
    end
    |> repo.update()
  end

  def get_all_non_finished_workers(schema, repo) do
    import Ecto.Query

    from(s in schema, where: s.state != "done")
    |> repo.all()
  end

  defp supervisor_name(module), do: :"#{module}.Supervisor"

  defp to_map(%_{} = v), do: Map.from_struct(v)
  defp to_map(%{} = v), do: v
end