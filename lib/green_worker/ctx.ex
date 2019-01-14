defmodule GreenWorker.Ctx do
  @moduledoc """
  Contains GreenWorker process context
  """

  defstruct store: %{}, cache: %{}
  @type t :: %GreenWorker.Ctx{store: Map.t(), cache: Map.t()}

  def new(collectable = %__MODULE__{}), do: collectable

  def new(store), do: new(store, %{})

  def new(store, cache), do: struct(__MODULE__, store: store, cache: cache)

  def auto_import, do: [put_store: 2, put_store: 3, put_cache: 2, put_cache: 3]

  def get_store!(ctx = %__MODULE__{}, key), do: Map.fetch!(ctx.store, key)

  def put_store(ctx = %__MODULE__{}, value), do: put(ctx, :store, value)

  def put_store(ctx = %__MODULE__{}, key, value) do
    put_store(ctx, Map.put(ctx.store, key, value))
  end

  def put_cache(ctx = %__MODULE__{}, value), do: put(ctx, :cache, value)

  def put_cache(ctx = %__MODULE__{}, key, value) do
    put_cache(ctx, Map.put(ctx.cache, key, value))
  end

  defp put(ctx = %__MODULE__{}, :store, value), do: new(value, ctx.cache)
  defp put(ctx = %__MODULE__{}, :cache, value), do: new(ctx.store, value)
end
