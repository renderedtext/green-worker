defmodule Support.AlternativeWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.AlternativeSchema,
    repo: Support.EctoRepo,
    key: :id_field,
    changeset: {Support.AlternativeSchema, :cs},
    state_field: :state_field,
    terminal_states: ["really_done"]

  @impl true
  def context_handler(%{:store => store = %{:state_field => "initial_state"}}) do
    store
    |> Map.put(:state_field, "really_done")
    |> GreenWorker.Ctx.new()
  end

  @impl true
  def context_handler(ctx = %{:store => %{:state_field => "really_done"}}) do
    ctx
  end
end
