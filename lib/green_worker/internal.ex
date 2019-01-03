defmodule GreenWorker.Internal do
  @moduledoc false

  def get_id(ctx, key), do: Map.get(ctx.store, key)

  def name(module, id), do: :"#{module}_#{id}"
end
