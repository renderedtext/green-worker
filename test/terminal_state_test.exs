defmodule TerminalStateTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.ShortTtlAndRehandlingWorker, as: Worker

  import TestHelpers, only: [start_family: 1]

  setup do
    TestHelpers.truncate_db()

    {:ok, %{}}
  end

  test "Stop GreenWorker after ttl expires" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "done"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert Process.alive?(pid)

    :timer.sleep(300)
    refute Process.alive?(pid)
  end

  test "Stop GreenWorker termination with get_context!() call" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "done"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert Process.alive?(pid)

    :timer.sleep(150)
    assert %{} = Worker.get_context!(id)
    :timer.sleep(150)
    assert %{} = Worker.get_context!(id)

    assert Process.alive?(pid)
  end
end
