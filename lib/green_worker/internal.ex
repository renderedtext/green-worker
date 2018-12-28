defmodule GreenWorker.Internal do
  @moduledoc false

  def get_id(ctx, key), do: Map.get(ctx, key)

end
