defmodule GreenWorker do
  @moduledoc """
  Documentation for GreenWorker.
  """

  defmodule Behaviour do
    @moduledoc false

    # @callback initial_query() :: Ecto.Query.t()
  end

  defmacro __using__(opts) do
    id                  = Util.get_mandatory_field(opts, :id)

    quote do
      @behaviour GreenWorker.Behaviour

      use GenServer
    end
  end
end
