defmodule GreenWorker do
  @moduledoc """
  A behavior module for implementing FSM-like family of workers.

  `GreenWorker` is used to define:
  - worker process code and
  - family supervision tree.

  ## Example
  Define GreenWorker family called `My.Worker`:

      defmodule My.Worker do
        use GreenWorker,
          schema: My.Schema,
          repo: My.EctoRepo

        @impl true
        def context_handler(ctx = %{:store => %{:state => "init"}}) do
          if ... do
            transition_to(ctx, "running")
          else
            ctx
          end
        end

        defp transition_to(ctx, new_state) do
          ctx.store
          |> Map.put(:state, new_state)
          |> GreenWorker.Ctx.new()
        end
      end

  `context_handler/1` is required by GreenWorker behavior.
  It is called
  - when worker is started and
  - each time worker context is changed
  - when `handle_context/1` is called explicitly

  Value that is passed in to the `context_handler/1` is worker's context,
  represented by `GreenWorker.Ctx` structure.

  ### Ctx
  `GreenWorker.Ctx` contains `store` and `cache` elements.

  As name suggest `store` is persisted each time it is changed and reloaded
  if/when worker is restarted.
  Initial value of `store` is loaded from the `repo` using `schema`.

  `cache` is lost each time worker is stopped.
  Initial value of `cache` is `%{}`.

  ### Supervision
  In order to start `My.Worker` family, start the family supervisor
  with the application:

      children = [
        My.EctoRepo,
        My.Worker.Supervisor
      ]

      opts = [strategy: :one_for_one, name: My.Supervisor]
      Supervisor.start_link(children, opts)

  Each time the supervisor is started `repo` is scanned and
  workers are started for rows that are not in "terminal state".

  ### Worker
  To persist context and start new worker use:

      > GreenWorker.store_and_start_supervised(My.Worker, %{id: 1, state: "init"})
      {:ok, #PID<0.95.0>}

  To get current worker's context:

      > GreenWorker.get_context(My.Worker, 1)
      {:ok, %GreenWorker.Ctx{cache: %{}, store: ...}

  ## Options
  Mandatory options:

  - `schema` is Ecto Schema that represents persisted part of worker context.
  Worker context also has part that is cached in memory and as such lost
  on every worker restart.

  - `repo` is Ecto Repo used to load/store `schema`.
  `schema` is used to communicate with `repo`.

  Optional:

  - `changeset` is Ecto changeset used to validate `schema` before it is persisted.
  `changeset` has `{module, function}` form.
  It is called as `module.function/2`.
  Defaults to `{schema, :changeset}`.

  - `key` uniquely indexed field in `schema` (usually primary key) used to
  identify the row in the DB table in load/store operations.
  Defaults to `:id`.

  """

  alias GreenWorker.Util
  alias GreenWorker.Queries

  defmodule Behaviour do
    @moduledoc false

    @callback context_handler(Map.t()) :: Ecto.Query.t()
  end

  defmacro __using__(opts) do
    # Module name representing Ecto schema to load/store context
    schema = Util.get_mandatory_field(opts, :schema)
    # Module name representing Eecto repo
    repo = Util.get_mandatory_field(opts, :repo)
    # Expects `{M,F}` tuple; default `{schema, :changeset}`
    # Calls `M.F/2`
    changeset = Util.get_optional_field(opts, :changeset, {schema, :changeset})
    # Uniquely indexed field name; default `:id`
    key = Util.get_optional_field(opts, :key, :id)
    state_field = Util.get_optional_field(opts, :state_field, :state)
    terminal_states = Util.get_optional_field(opts, :terminal_states, ["done"])

    quote do
      @behaviour GreenWorker.Behaviour

      use GenServer

      import GreenWorker.Macros
      import GreenWorker.Ctx, only: unquote(GreenWorker.Ctx.auto_import())

      @state_field unquote(state_field)

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
          key: unquote(key),
          state_field: unquote(state_field),
          terminal_states: unquote(terminal_states)
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

      # ctx = {stored, cached}
      @impl true
      def init(id) do
        Keyword.put([], unquote(key), id)
        |> Queries.read(unquote(schema), unquote(repo))
        |> case do
          nil ->
            {:id_not_found, id}

          stored ->
            handle_context(id)

            {:ok, GreenWorker.Ctx.new(stored)}
        end
      end

      @impl true
      def handle_call(:get_context, _from, ctx) do
        {:reply, ctx, ctx}
      end

      @impl true
      def handle_cast(:handle_context, ctx) do
        new_ctx =
          ctx
          |> context_handler()

        if new_ctx != ctx do
          handle_context(get_id(ctx))

          {:ok, _} =
            Queries.update(ctx, new_ctx, unquote(changeset), unquote(repo))
        end

        {:noreply, new_ctx}
      end

      defp name(id), do: GreenWorker.Internal.name(__MODULE__, id)

      defp get_id(ctx), do: GreenWorker.Internal.get_id(ctx, unquote(key))

      ##### Supervisor

      # This alias is available to sub-module Supervisor (lexical scoping)
      alias __MODULE__, as: ContainingModule

      defmodule Supervisor do
        @moduledoc false

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
    Call `store/2` and if successful call `start_supervised/2`.

    Before any other action check if process already exists.
  """
  def store_and_start_supervised(module, initial) do
    %{key: key} = module.get_config()

    id =
      GreenWorker.Ctx.new(initial)
      |> GreenWorker.Internal.get_id(key)

    if pid = whereis(module, id) do
      {:ok, pid}
    else
      store(module, initial)
      |> insert_idempotency(key)
      |> start_supervised_if(module, id)
    end
  end

  @doc """
  Persist initial context into DB.

  `initial` is sanitized through changeset specified in `module` before it is
  persisted.
  """
  def store(module, initial) do
    %{schema: schema, repo: repo, changeset: changeset} = module.get_config()

    Queries.insert(initial, changeset, schema, repo)
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
    case get_context!(module, id) do
      error = {:error, _} -> error
      response -> {:ok, response}
    end
  rescue
    error ->
      {:error, error}
  catch
    :throw, error ->
      {:error, error}
  end

  def get_context!(module, id) do
    module.get_context!(id)
  catch
    :exit, {:noproc, {GenServer, :call, _}} ->
      case start_supervised(module, id) do
        {:ok, _} -> module.get_context!(id)

        {:error, error} -> throw(error)
      end
  end

  defp do_get_context(module, id) do
    {:ok, module.get_context!(id)}
  end

  @doc """
    Return pid of specified worker if running or nil otherwise.
  """
  def whereis(module, id) do
    GreenWorker.Internal.name(module, id)
    |> Process.whereis()
  end

  defp insert_idempotency(insert_resp = {:ok, _}, _key), do: insert_resp

  defp insert_idempotency(
         {:error, %{action: :insert, errors: [{k, {"has already been taken", _}}]}},
         key
       )
       when k == key do
    {:ok, :duplicate}
  end

  defp insert_idempotency(insert_resp = {:error, _}, _key), do: insert_resp

  defp start_supervised_if({:ok, _}, module, id), do: start_supervised(module, id)
  defp start_supervised_if(error = {:error, _}, _module, _id), do: error

  defp supervisor_name(module), do: :"#{module}.Supervisor"
end
