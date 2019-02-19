defmodule TerminalStateTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.ReloadWorker, as: Worker

  import TestHelpers, only: [start_family: 1]

  setup do
    TestHelpers.truncate_db()

    {:ok, %{}}
  end

  test "reload" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert Process.alive?(pid)

    assert {:ok, response} = GreenWorker.wait_for_state(Worker, id, "next_state")
  end

  test "reload and schedule next state" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert Process.alive?(pid)

    assert {:ok, response} = GreenWorker.wait_for_state(Worker, id, "done")
  end
end
