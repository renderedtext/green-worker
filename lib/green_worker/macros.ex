defmodule GreenWorker.Macros do
  @moduledoc false

  defmacro handle(state: state, return: :default) do
    quote do
      @impl true
      def context_handler(ctx = %{:store => %{@state_field_name => unquote(state)}}) do
        ctx
      end
    end
  end

  defmacro handle([state: state], do: body) do
    quote do
      @impl true
      def context_handler(var!(ctx) = %{:store => %{@state_field_name => unquote(state)}}) do
        unquote(body)
      end
    end
  end

  defmacro handle([call: call, with_args: args], do: body) do
    # Generate handle_call() + GenServer.call pair of functions
    # Add GreenWorker.call(family, id, call, args)
  end
end
