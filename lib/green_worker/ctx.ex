defmodule GreenWorker.Ctx do
  @moduledoc """
  Contains GreenWorker process context
  """

  defstruct stored: %{}, cached: %{}
  @type t :: %GreenWorker.Ctx{stored: Map.t, cached: Map.t}

  def new(collectable = %GreenWorker.Ctx{}), do: collectable

  def new(store), do: new(store, %{})

  def new(store, cache), do: struct(__MODULE__, stored: store, cache: cache)
end
