defmodule GreenWorker.Internal do
  @moduledoc """
  Functions and macros used by GreenWorker module.
  """

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

  @doc """
  Used from GreenWorker module.

  ## Example
      generate_with_ensure_started(:get_context, 2)

  Generates functions `GreenWorker.get_context(SomeWorker, id)` and
  `GreenWorker.get_context!(SomeWorker, id)`.
  Both call `SomeWorker.get_context!(id)`
  """
  defmacro generate_with_ensure_started(fname, additional_args \\ [], defaults \\ []) do
    bang_fname = Atom.to_string(fname) <> "!"

    defaults = adjust_defaults(defaults, additional_args)

    if length(additional_args) != length(defaults) do
      raise "Size mismatch: length(additional_args) == #{length(additional_args)} and length(defaults) == #{length(defaults)}"
    end

    args = Enum.map(additional_args, fn arg -> Macro.var(arg, __MODULE__) end)

    params = create_params(args, defaults)

    quote do
      def unquote(:"#{fname}")(family, id, unquote_splicing(params)) do
        case unquote(:"#{bang_fname}")(family, id, unquote_splicing(args)) do
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

      @doc """
      Similar to function without "bang" (`!`) except it raises/throws exceptions.
      """
      def unquote(:"#{bang_fname}")(family, id, unquote_splicing(params)) do
        family.unquote(:"#{bang_fname}")(id, unquote_splicing(args))
      catch
        :exit, {:noproc, {GenServer, :call, _}} ->
          case start_supervised(family, id) do
            {:ok, _} -> family.get_context!(id)

            {:error, {:already_started, _}} -> family.get_context!(id)

            {:error, error} -> throw(error)
          end
      end
    end
  end

  defp adjust_defaults(_defaults = [], additional_args),
    do: List.duplicate(:none, length(additional_args))

  defp adjust_defaults(defaults, _additional_args), do: defaults

  defp create_params(args, defaults) do
    args
    |> Enum.zip(defaults)
    |> Enum.map(fn
      {var, :none} -> var

      {var, default} -> quote do unquote(var) \\ unquote(default) end
    end)
  end
end
