defmodule GreenWorker.Internal do
  @moduledoc false

  def get_id(ctx, key_field_name), do: Map.get(ctx.store, key_field_name)

  def name(module, id), do: :"#{module}_#{id}"

  def via_tuple(module, id), do: {:via, :swarm, name(module, id)}

  def whereis(module, id) do
    Swarm.whereis_name(name(module, id))
    |> case do
      :undefined -> nil
      pid -> pid
    end
  end

  @doc """
  Used when context is chanded to assert that state field changed also
  """
  def assert_state_field_changed(ctx, new_ctx, state_field_name) do
    state_field = Map.get(ctx.store, state_field_name)
    new_state_field = Map.get(new_ctx.store, state_field_name)

    if state_field == new_state_field do
      exit(state_field_fault_error_message(new_ctx))
    end
  end

  defp state_field_fault_error_message(new_ctx) do
    [
      "GreenWorker validation error:",
      "ctx changed but ctx.store.@state_field_name did NOT!",
      " ==> ",
      "New context: #{inspect(new_ctx)}"
    ]
    |> Enum.join(" ")
  end

  defmacro generate_with_ensure_started(fname, arg_count) when arg_count < 2 do
    raise "arg_count must be 2 or greater"
  end

  defmacro generate_with_ensure_started(fname, arg_count) do
    arg_count |> IO.inspect(label: "QQQQQQQQQQQQQQQQQQQQQQQQQQ")
    bang_fname = Atom.to_string(fname) <> "!"
    args =
      List.duplicate(1, arg_count - 2)
      |> Enum.with_index()
      |> Enum.map(fn {_, index} -> Macro.var(:"a#{index}", __MODULE__) end)
    args |> IO.inspect(label: "FFFFFFFFFFF")

    quote do
      def unquote(:"#{fname}")(module, id, unquote_splicing(args)) do
        case unquote(:"#{bang_fname}")(module, id, unquote_splicing(args)) do
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

      def unquote(:"#{bang_fname}")(module, id, unquote_splicing(args)) do
        module.unquote(:"#{bang_fname}")(id, unquote_splicing(args))
      catch
        :exit, {:noproc, {GenServer, :call, _}} ->
          case start_supervised(module, id) do
            {:ok, _} -> module.get_context!(id)

            {:error, {:already_started, _}} -> module.get_context!(id)

            {:error, error} -> throw(error)
          end
     end
    end
  end
end
