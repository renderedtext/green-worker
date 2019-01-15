defmodule RehandlingPeriodTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.ShortTtlAndRehandlingWorker, as: Worker

  import TestHelpers, only: [start_family: 1]

  setup do
    TestHelpers.truncate_db()

    {:ok, %{}}
  end

  test "Rehandle GreenWorker after rehandling_period expires" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "running"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert %{store: %{state: "running"}} = Worker.get_context!(id)

    :timer.sleep(150)
    assert %{store: %{state: "done"}} = Worker.get_context!(id)
  end

  test "Do not rehandle GreenWorker if not idle for rehandling_period" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "running"}

    assert {:ok, sup} = start_family(Worker)

    assert {:ok, pid} = GreenWorker.store_and_start_supervised(Worker, ctx)
    assert %{store: %{state: "running"}} = Worker.get_context!(id)

    for i <- 1..30 do
      :timer.sleep(5)
      assert %{store: %{state: "running"}} = Worker.get_context!(id)
    end
  end
end
