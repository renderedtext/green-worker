defmodule GreenWorker.Imports do
  @moduledoc """

  """

  alias GreenWorker.Ctx, as: Ctx

  defmacro handle([state: state], do: body) do
    quote do
      @impl true
      def context_handler(var!(ctx) = %{:store => %{@state_field => unquote(state)}}) do
          unquote(body)
        end
    end
  end

  def put_store(ctx = %Ctx{}, value), do: put(ctx, :store, value)

  def put_store(ctx = %Ctx{}, key, value) do
    put_store(ctx, Map.put(ctx.store, key, value))
  end

  def put_cache(ctx = %Ctx{}, value), do: put(ctx, :cache, value)

  def put_cache(ctx = %Ctx{}, key, value) do
    put_cache(ctx, Map.put(ctx.cache, key, value))
  end

  defp put(ctx = %Ctx{}, :store, value), do: GreenWorker.Ctx.new(value, ctx.cache)
  defp put(ctx = %Ctx{}, :cache, value), do: GreenWorker.Ctx.new(ctx.store, value)
end
