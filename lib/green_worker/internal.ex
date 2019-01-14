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
end
