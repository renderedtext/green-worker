defmodule WaitForStateTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.BasicTransitionWithChangeset, as: Worker

  import TestHelpers, only: [start_family: 1]

  setup do
    TestHelpers.truncate_db()

    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert is_pid(pid)

    {:ok, %{id: id, ctx: ctx, pid: pid}}
  end

  test "Wait for GreenWorker to reach done state", %{id: id} do
    Worker.wait_for_state!(id, "done")
    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end

  test "GreenWorker does not reach desired state", %{id: id} do
    assert_raise(
      GreenWorker.Exceptions.DeadlineExceededError,
      fn -> Worker.wait_for_state!(id, "wrong_state_name", 200) end
    )
  end

  test "GreenWorker.wait_for_state/3 - reach done state", %{id: id, pid: pid} do
    GenServer.stop(pid)

    :timer.sleep 50
    GreenWorker.wait_for_state(Worker, id, "done")

    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end

  test "GreenWorker.wait_for_state/4 - reach done state", %{id: id, pid: pid} do
    GenServer.stop(pid)

    :timer.sleep 50
    GreenWorker.wait_for_state(Worker, id, "done", 500)

    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end

  test "GreenWorker.wait_for_state/5 - reach done state", %{id: id, pid: pid} do
    GenServer.stop(pid)

    :timer.sleep 50
    GreenWorker.wait_for_state(Worker, id, "done", 500, 3)

    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end
end
