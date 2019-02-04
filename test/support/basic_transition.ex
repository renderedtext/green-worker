defmodule Support.BasicTransition do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo

  handle state: "init" do
    PubSub.subscribe(self(), BasicTransitionToWorker)

    PubSub.publish(BasicTransition, {ctx.store.id, "pending"})

    ctx
    |> put_store(:state, "pending")
  end

  handle state: "pending" do
    if Map.get(ctx, :can_advance) == true do
      Map.delete(ctx, :can_advance)
      PubSub.publish(BasicTransition, {ctx.store.id, "done"})

      ctx
      |> put_store(:state, "done")
    else
      ctx
    end
  end

  handle state: "done" do
    PubSub.publish(BasicTransition, {ctx.store.id, "done"})

    ctx
  end

  @impl true
  def handle_info({id, :can_advance}, ctx) do
    schedule_handling(id)

    {:noreply, Map.put(ctx, :can_advance, true)}
  end
end
