defmodule Support.NoActionWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state")
  end
end
