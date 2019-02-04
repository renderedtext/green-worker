defmodule Support.ShortTtlAndRehandlingWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    ttl_in_terminal_state: 200,
    rehandling_period: 10

  handle state: "running" do
    counter = Map.get(ctx.cache, :counter, 0) + 1
    state = if(counter > 3, do: "done", else: "running")

    ctx
    |> put_cache(:counter, counter)
    |> put_store(:state, state)
  end

  handle state: "done" do
    ctx
  end
end
