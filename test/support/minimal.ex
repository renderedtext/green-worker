defmodule Support.Minimal do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx = %{:store => %{:state => "init"}}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGG state")
  end

  @impl true
  def context_handler(ctx = %{store: %{:state => "done"}}) do
    ctx |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGGGGG state2")
  end
end
