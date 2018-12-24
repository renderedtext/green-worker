defmodule Support.BasicTransition do
  use GreenWorker,
  schema: Support.BasicSchema,
  repo: Support.DummyEctoRepo

  @impl true
  def context_handler(ctx = %{:state => "init"}) do
    PubSub.subscribe(self(), BasicTransitionToWorker)

    PubSub.publish(BasicTransition, {ctx.id, "pending"})

    ctx |> Map.put(:state, "pending")
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:state => "pending"}) do
    if Map.get(ctx, :can_advance) == true do
      Map.delete(ctx, :can_advance)
      PubSub.publish(BasicTransition, {ctx.id, "done"})

      ctx
      |> Map.put(:state, "done")
      |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
    else
      ctx
    end
  end

  @impl true
  def context_handler(ctx = %{:state => "done"}) do
    PubSub.publish(BasicTransition, {ctx.id, "done"})

    ctx     |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  def handle_info({id, :can_advance}, ctx) do
    handle_context(id)

    {:noreply, Map.put(ctx, :can_advance, true)}
  end
end
