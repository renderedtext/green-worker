defmodule Support.StateFieldFailWorker do
  @moduledoc false

  use GreenWorker,
    schema: Support.BasicSchema,
    repo: Support.EctoRepo


  handle state: "init" do
    :timer.sleep(50)

    ctx
    |> put_store(:result, "pass")
  end

  handle state: "done" do
    ctx
  end
end
