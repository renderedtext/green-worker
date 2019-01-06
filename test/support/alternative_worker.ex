defmodule Support.AlternativeWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.AlternativeSchema,
    repo: Support.EctoRepo,
    key: :id_field,
    changeset: {Support.AlternativeSchema, :cs},
    state_field_name: :state_field,
    terminal_states: ["really_done"]

  handle state: "initial_state" do
    ctx
    |> put_cache(%{id: ctx.store.id_field})
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG 0")
    |> put_store(:state_field, "really_done")
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG 1")
  end

  # @impl true
  # def context_handler(ctx = %{:store => %{:state_field => "really_done"}}) do
  #   ctx
  # end

  handle state: "really_done" do
    ctx
    |> IO.inspect(label: "GGGGGGGGGGGGGGGGGGGG done")
  end
end
