defmodule Support.Minimal do
  use GreenWorker,
  schema: Support.BasicSchema,
  repo: Support.DummyEctoRepo

  @impl true
  def context_handler(ctx = %{:state => "init"}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state")
  end

  @impl true
  def context_handler(ctx = %{:state => "done"}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGGGGG state2")
  end
end
