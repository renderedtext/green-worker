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

  - `changeset` - Ecto changeset used to validate `schema` before it is persisted.
  `changeset` has `{module, function}` form.
  It is called as `module.function/2`.
  Defaults to `{schema, :changeset}`.

  - `key_field_name` - uniquely indexed field in `schema` (usually primary key)
  used to identify the row in the DB table in load/store operations.
  Defaults to `:id`.

  - `state_field_name` - name of the field in the schema containing state.

  - `terminal_states` - list of terminal states.

  - ttl_in_terminal_state - worker will be stopped after `ttl_in_terminal_state`
  period of inactivity.

  - rehandling_period - state handling will be rescheduled after `rehandling_period`
  of inactivity.
  """

  alias GreenWorker.Util
  alias GreenWorker.Queries
  alias GreenWorker.Internal
  alias GreenWorker.Ctx
  alias GreenWorker.Exceptions.DeadlineExceededError

  require GreenWorker.Internal

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
    key_field_name = Util.get_optional_field(opts, :key_field_name, :id)
    state_field_name = Util.get_optional_field(opts, :state_field_name, :state)
    terminal_states = Util.get_optional_field(opts, :terminal_states, ["done"])
    # After "ttl_in_terminal_state" milliseconds of inactivity,
    # worker will be stopped.
    ttl_in_terminal_state = Util.get_optional_field(opts, :ttl_in_terminal_state, :timer.minutes(30))
    rehandling_period = Util.get_optional_field(opts, :rehandling_period, :infinity)

    quote do
      @behaviour GreenWorker.Behaviour

      use GenServer

      import GreenWorker.Macros
      import GreenWorker.Ctx, only: unquote(GreenWorker.Ctx.auto_import())

      @state_field_name unquote(state_field_name)

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
          key_field_name: unquote(key_field_name),
          state_field_name: unquote(state_field_name),
          terminal_states: unquote(terminal_states),
          ttl_in_terminal_state: unquote(ttl_in_terminal_state),
          rehandling_period: unquote(rehandling_period)
        }
      end

      @doc """
      Return context if worker process is alive or
      call exit in the caller process if worker process is not alive.
      """
      def get_context!(id) do
        GenServer.call(name(id), :get_context)
      end

      def schedule_handling(id) do
        GenServer.cast(name(id), :handle_context)
      end

      def wait_for_state!(id, state_name, timeout \\ 1_000, sleep \\ 100)

      def wait_for_state!(_id, state_name, timeout, _sleep) when timeout < 0 do
        raise DeadlineExceededError,
          "Deadline expired before '#{state_name}' state was reached"
      end

      def wait_for_state!(id, state_name, timeout, sleep) do
        ctx = get_context!(id)
        current_state_name = get_state_name(ctx)

        if current_state_name == state_name do
          ctx
        else
          :timer.sleep(sleep)
          wait_for_state!(id, state_name, timeout - sleep)
        end
      end

      @impl true
      def init(id) do
        case load(id) do
          nil ->
            {:id_not_found, {__MODULE__, id}}

          store_data ->
            schedule_handling(id)

            {:ok, GreenWorker.Ctx.new(store_data)}
        end
      end

      @impl true
      def handle_call(:get_context, _from, ctx) do
        {:reply, ctx, ctx}
        |> timeout_in_return_tuple()
      end

      @impl true
      def handle_cast(:handle_context, ctx) do
        new_ctx = context_handler(ctx)

        {:noreply, handle_context_post_processing(ctx, new_ctx)}
        |> timeout_in_return_tuple()
      end

      @impl true
      def handle_info(:timeout, ctx) do
        if in_terminal_state?(ctx) do
          {:stop, :shutdown, ctx}
        else
          schedule_handling(get_id(ctx))

          {:noreply, ctx}
          |> timeout_in_return_tuple()
        end
      end

      defp timeout_in_return_tuple(ret_tuple) do
        ctx = ret_tuple |> Tuple.to_list |> List.last

        if in_terminal_state?(ctx) do
          Tuple.append(ret_tuple, unquote(ttl_in_terminal_state))
        else
          Tuple.append(ret_tuple, unquote(rehandling_period))
        end
      end

      defp handle_context_post_processing(ctx, new_ctx) do
        cond do
          new_ctx.store == :reload ->
            Ctx.new(load(ctx.store.unquote(key_field_name)))

          ctx.store != new_ctx.store ->
            Internal.assert_state_field_changed(ctx, new_ctx, unquote(state_field_name))
            schedule_handling(get_id(ctx))
            {:ok, _} = Queries.update(ctx, new_ctx, unquote(changeset), unquote(repo))
            new_ctx

          true ->
            new_ctx
        end
      end

      defp in_terminal_state?(ctx), do: get_state_name(ctx) in unquote(terminal_states)

      defp get_state_name(ctx), do: ctx.store.unquote(state_field_name)

      defp name(id), do: GreenWorker.Internal.via_tuple(__MODULE__, id)

      defp get_id(ctx), do: GreenWorker.Internal.get_id(ctx, unquote(key_field_name))

      defp load(id) do
        Keyword.put([], unquote(key_field_name), id)
        |> Queries.read(unquote(schema), unquote(repo))
      end
    end
  end

  ############################# __using__ ##############################

  @doc """
    Call `store/2` and if successful call `start_supervised/2`.

    Before any other action check if process already exists.
  """
  def store_and_start_supervised(module, initial) do
    %{key_field_name: key_field_name} = module.get_config()

    id =
      GreenWorker.Ctx.new(initial)
      |> GreenWorker.Internal.get_id(key_field_name)

    if pid = whereis(module, id) do
      {:ok, pid}
    else
      store(module, initial)
      |> insert_idempotency(key_field_name)
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
  Internal.generate_with_ensure_started(:get_context, 2)

  Internal.generate_with_ensure_started(:wait_for_state, 3)
  Internal.generate_with_ensure_started(:wait_for_state, 4)
  Internal.generate_with_ensure_started(:wait_for_state, 5)

  @doc """
    Return pid of specified worker if running or nil otherwise.
  """
  def whereis(module, id) do
    GreenWorker.Internal.whereis(module, id)
  end

  defp insert_idempotency(insert_resp = {:ok, _}, _key), do: insert_resp

  defp insert_idempotency(
         {:error, %{action: :insert, errors: [{k, {"has already been taken", _}}]}},
         key_field_name
       )
       when k == key_field_name do
    {:ok, :duplicate}
  end

  defp insert_idempotency(insert_resp = {:error, _}, _key), do: insert_resp

  defp start_supervised_if({:ok, _}, module, id), do: start_supervised(module, id)
  defp start_supervised_if(_error = {:error, {:already_started, _}}, module, id),
    do: start_supervised(module, id)
  defp start_supervised_if(error = {:error, _}, _module, _id), do: error

  defp supervisor_name(module), do: GreenWorker.Family.Supervisor.dynamic_name(module)
end
