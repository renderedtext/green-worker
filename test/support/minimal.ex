defmodule Support.Minimal do
  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx = %{:stored => %{:state => "init"}}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state")
  end

  @impl true
  def context_handler(ctx = %{stored: %{:state => "done"}}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGGGGG state2")
  end
end
