defmodule GreenWorker do
  @moduledoc """
  Documentation for GreenWorker.
  """

  alias GreenWorker.Util

  defmodule Behaviour do
    @moduledoc false

    @callback context_handler(Map.t()) :: Ecto.Query.t()
  end

  defmacro __using__(opts) do
    # Module name representing Ecto schema to load/store context
    schema = Util.get_mandatory_field(opts, :schema)
    # Module name representingEecto repo
    repo = Util.get_mandatory_field(opts, :repo)
    # Expects `{M,F}` tuple; default `nil`
    # If not nil calls `M.F/2`
    changeset = Util.get_mandatory_field(opts, :changeset)
    # Uniquely indexed field name; default `:id`
    key = Util.get_optional_field(opts, :key, :id)

    quote do
      @behaviour GreenWorker.Behaviour

      use GenServer

      def start_link(id) do
        GenServer.start_link(__MODULE__, id, name: name(id))
      end

      def child_spec(args) do
        super(args)
        |> Map.put(:restart, :transient)
      end

      def get_config do
        %{
          schema: unquote(schema),
          repo: unquote(repo),
          changeset: unquote(changeset),
          key: unquote(key)
        }
      end

      @doc """
      Return context if worker process is alive or
      call exit in the caller process if worker process is not alive.
      """
      def get_context!(id) do
        GenServer.call(name(id), :get_context)
      end

      def handle_context(id) do
        GenServer.cast(name(id), :handle_context)
      end

      @impl true
      def init(id) do
        Keyword.put([], unquote(key), id)
        |> GreenWorker.Internal.load_context(unquote(schema), unquote(repo))
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
          handle_context(get_id(ctx))

          {:ok, _} =
            GreenWorker.Internal.store_context(ctx, new_ctx, unquote(changeset), unquote(repo))
        end

        {:noreply, new_ctx}
      end

      defp name(id), do: GreenWorker.Internal.name(__MODULE__, id)

      defp get_id(ctx), do: GreenWorker.Internal.get_id(ctx, unquote(key))

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
            config: ContainingModule.get_config()
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
    Persist initial context into DB and start worker.

    Context is sanitized through changeset specified in `module` before it is
    persisted.
  """
  def store_context_and_start_supervised(module, ctx) do
    %{schema: schema, repo: repo, changeset: changeset, key: key} = module.get_config()

    id = GreenWorker.Internal.get_id(ctx, key)

    if pid = whereis(module, id) do
      {:ok, pid}
    else
      do_store_context(ctx, changeset, schema, repo)
      |> store_context_idempotency(key)
      |> start_supervised_if(module, id)
    end
  end

  def store_context(module, ctx) do
    %{schema: schema, repo: repo, changeset: changeset} = module.get_config()

    do_store_context(ctx, changeset, schema, repo)
  end

  @doc """
  Start GreenWorker process under dynamic supervisor.

  Call is idempotent - if called for existing process returns pid of
  previously started process.

  ## Example

      {:ok, pid} = start_supervised(WorkerModule, "worker_unique_id")
  """
  def start_supervised(module, id) when is_binary(id) do
    if pid = whereis(module, id) do
      {:ok, pid}
    else
      DynamicSupervisor.start_child(supervisor_name(module), {module, id})
    end
  end

  @doc """
  Start worker if not running and return context.

  If worker start fails, return error.
  """
  def get_context(module, id) do
    module.get_context!(id)
  catch
    :exit, {:noproc, {GenServer, :call, _}} ->
      case start_supervised(module, id) do
        {:ok, _} -> module.get_context!(id)
        error = {:error, _} -> error
      end
  end

  @doc """
    Return pid of specified worker if running or nil otherwise.
  """
  def whereis(module, id) do
    GreenWorker.Internal.name(module, id)
    |> Process.whereis()
  end

  defp do_store_context(ctx, {m, f}, schema, repo) do
    change =
      GreenWorker.Internal.call_changeset(m, f, [struct(schema), ctx])
      |> IO.inspect(label: "DDDDDDDDDDDDDDDDDDD change")

    if change.valid? do
      change
      |> repo.insert()
      |> IO.inspect(label: "DDDDDDDDDDDDDDDDDDD insert")
    else
      {:error, change}
    end
  end

  defp store_context_idempotency(store_resp = {:ok, _}, _key), do: store_resp

  defp store_context_idempotency(
         {:error, %{action: :insert, errors: [{k, {"has already been taken", _}}]}},
         key
       )
       when k == key do
    {:ok, :duplicate}
  end

  defp store_context_idempotency(store_resp = {:error, _}, _key), do: store_resp

  defp start_supervised_if({:ok, _}, module, id), do: start_supervised(module, id)
  defp start_supervised_if(error = {:error, _}, _module, _id), do: error

  defp supervisor_name(module), do: :"#{module}.Supervisor"
end
