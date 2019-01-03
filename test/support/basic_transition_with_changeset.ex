defmodule Support.BasicTransitionWithChangeset do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "init"}}) do
    ctx
    |> Map.put(:state, "pending")
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "pending"}}) do
    ctx
    |> Map.put(:state, "done")
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "done"}}) do
    PubSub.publish(BasicTransitionWithChangeset, {ctx.stored.id, ctx.stored.state})

    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end
end
