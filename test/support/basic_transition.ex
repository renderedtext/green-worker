defmodule Support.BasicTransition do
  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(%{:stored => store = %{:state => "init"}}) do
    PubSub.subscribe(self(), BasicTransitionToWorker)

    PubSub.publish(BasicTransition, {store.id, "pending"})

    store
    |> Map.put(:state, "pending")
    |> GreenWorker.Ctx.new()
    |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "pending"}}) do
    if Map.get(ctx, :can_advance) == true do
      Map.delete(ctx, :can_advance)
      PubSub.publish(BasicTransition, {ctx.stored.id, "done"})

      ctx.stored
      |> Map.put(:state, "done")
      |> GreenWorker.Ctx.new
      |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
    else
      ctx
    end
  end

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "done"}}) do
    PubSub.publish(BasicTransition, {ctx.stored.id, "done"})

    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state exit")
  end

  @impl true
  def handle_info({id, :can_advance}, ctx) do
    handle_context(id)

    {:noreply, Map.put(ctx, :can_advance, true)}
  end
end
