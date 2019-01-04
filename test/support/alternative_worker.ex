defmodule Support.AlternativeWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.AlternativeSchema,
    repo: Support.EctoRepo,
    key: :id_field,
    changeset: {Support.AlternativeSchema, :cs},
    state_field: :state_field,
    terminal_states: ["really_done"]


  handler for_state: "initial_state" do
  # @impl true
  # def context_handler(%{:store => store = %{:state_field => "initial_state"}}) do
    ctx = update_cache(%{id: ctx.store.id_field})
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG")

    ctx.store
    |> Map.put(:state_field, "really_done")
    |> update_store()
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG")
  end

  # @impl true
  # def context_handler(ctx = %{:store => %{:state_field => "really_done"}}) do
  #   ctx
  # end

  handler for_state: "really_done" do
    ctx
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG")
  end
end
