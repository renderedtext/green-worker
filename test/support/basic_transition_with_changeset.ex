defmodule Support.BasicTransitionWithChangeset do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo,
    changeset: {Support.BasicSchema, :changeset}

  @impl true
  def context_handler(ctx = %{:store => %{:state => "init"}}) do
    ctx
    |> put_store(:state, "pending")
  end

  @impl true
  def context_handler(ctx = %{:store => %{:state => "pending"}}) do
    ctx
    |> put_store(:state, "done")
  end

  @impl true
  def context_handler(ctx = %{:store => %{:state => "done"}}) do
    PubSub.publish(BasicTransitionWithChangeset, {ctx.store.id, ctx.store.state})

    ctx
  end
end
