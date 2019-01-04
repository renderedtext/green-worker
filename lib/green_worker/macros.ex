defmodule GreenWorker.Macros do
  @moduledoc """

  """

  defmacro handle([state: state], do: body) do
    quote do
      @impl true
      def context_handler(var!(ctx) = %{:store => %{@state_field => unquote(state)}}) do
          unquote(body)
        end
    end
  end
end
