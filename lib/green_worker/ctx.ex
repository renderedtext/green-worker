defmodule GreenWorker.Ctx do
  @moduledoc """
  Contains GreenWorker process context
  """

  defstruct store: %{}, cache: %{}
  @type t :: %GreenWorker.Ctx{store: Map.t, cache: Map.t}

  def new(collectable = %GreenWorker.Ctx{}), do: collectable

  def new(store), do: new(store, %{})

  def new(store, cache), do: struct(__MODULE__, store: store, cache: cache)
end
