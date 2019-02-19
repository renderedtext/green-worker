defmodule Support.ReloadWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo

  handle state: "init" do
    ctx.store
    |> Support.BasicSchema.changeset(%{state: "next_state"})
    |> Support.EctoRepo.update

    put_store(ctx, :reload)
  end

  handle state: "next_state" do
    put_store(ctx, :state, "done")
  end

  handle state: "done", return: :default
end
