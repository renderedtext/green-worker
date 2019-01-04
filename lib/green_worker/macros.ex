defmodule GreenWorker.Macros do
  @moduledoc """

  """

  defmacro handler([for_state: state], do: body) do
    quote do
      @impl true
      def context_handler(var!(ctx) = %{:store => %{@state_field => unquote(state)}}) do
          unquote(body)
        end
    end
  end

  defmacro update_store(store) do
    quote do
      GreenWorker.Ctx.new(unquote(store), var!(ctx).cache)
    end
  end

  defmacro update_cache(cache) do
    quote do
      GreenWorker.Ctx.new(var!(ctx).store, unquote(cache))
    end
  end
end
