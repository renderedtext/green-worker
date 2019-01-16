defmodule WaitForStateTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.BasicTransitionWithChangeset, as: Worker

  import TestHelpers, only: [start_family: 1]

  setup do
    TestHelpers.truncate_db()

    {:ok, %{}}
  end

  test "Wait for GreenWorker to reach done state" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert is_pid(pid)

    Worker.wait_for_state!(id, "done")
    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end

  test "GreenWorker does not reach desired state" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert is_pid(pid)

    assert_raise(
      GreenWorker.Exceptions.DeadlineExceededError,
      fn -> Worker.wait_for_state!(id, "wrong_state_name", 200) end
    )
  end
end
