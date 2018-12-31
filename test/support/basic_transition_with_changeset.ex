defmodule Support.BasicTransitionWithChangeset do
  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx = %{:state => "init"}) do
    ctx
    |> Map.put(:state, "pending")
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:state => "pending"}) do
    ctx
    |> Map.put(:state, "done")
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:state => "done"}) do
    PubSub.publish(BasicTransitionWithChangeset, {ctx.id, ctx.state})

    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end
end
