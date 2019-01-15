defmodule Support.ShortTtlWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    ttl_in_terminal_state: 200

  @impl true
  def context_handler(ctx) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG ShortTtlWorker state")
  end
end
