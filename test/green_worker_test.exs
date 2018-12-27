defmodule GreenWorkerTest do
  use ExUnit.Case
  doctest GreenWorker

  test "start GreenWorker supervisor tree and children" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    id2 = "c6d81146-0847-11e9-b6f4-482ae31adfd4"

    assert {:ok, sup} = Supervisor.start_link(Support.Minimal.Supervisor, strategy: :one_for_one)
    assert {:ok, pid} = GreenWorker.start_supervised(Support.Minimal, id1)
    assert is_pid(pid)
    assert {:error, {:already_started, _}} = GreenWorker.start_supervised(Support.Minimal, id1)
    assert {:ok, _} = GreenWorker.start_supervised(Support.Minimal, id2)

    Supervisor.stop(sup)
  end

  test "state transitions" do
    PubSub.subscribe(self(), BasicTransition)
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"

    assert {:ok, sup} = Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)
    assert {:ok, _} = GreenWorker.start_supervised(Support.BasicTransition, id1)

    wait_for(id1, "pending")
    assert %{state: "pending"} = Support.BasicTransition.get_context(id1)
    PubSub.publish(BasicTransitionToWorker, {id1, :can_advance})

    wait_for(id1, "done")
    assert %{state: "done"} = Support.BasicTransition.get_context(id1)

    Supervisor.stop(sup)
  end

  test "automatic dynamic supervisor initialization" do
    PubSub.subscribe(self(), BasicTransition)

    id1 = "86781246-0847-0000-0000-123456789012"
    id2 = "86781246-0847-0000-0001-123456789012"

    assert {:ok, sup} = Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)

    PubSub.publish(BasicTransitionToWorker, {id1, :can_advance})
    PubSub.publish(BasicTransitionToWorker, {id2, :can_advance})

    wait_for(id1, "done")
    wait_for(id2, "done")

    assert %{state: "done"} = Support.BasicTransition.get_context(id1)
    assert %{state: "done"} = Support.BasicTransition.get_context(id2)

    Supervisor.stop(sup)
  end

  test "start worker for non-existent id" do
    id1 = "non-existent"

    assert {:ok, sup} = Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)
    assert {:error, {:bad_return_value, {:id_not_found, _}}} =
      GreenWorker.start_supervised(Support.BasicTransition, id1)

    Supervisor.stop(sup)
  end

  test "automatic dynamic supervisor initialization with changeset" do
    PubSub.subscribe(self(), BasicTransitionWithChangeset)

    id1 = "86781246-0847-0000-0000-123456789012"
    id2 = "86781246-0847-0000-0001-123456789012"

    assert {:ok, sup} = Supervisor.start_link(Support.BasicTransitionWithChangeset.Supervisor, strategy: :one_for_one)

    wait_for(id1, "done")
    wait_for(id2, "done")

    assert %{state: "done"} = Support.BasicTransitionWithChangeset.get_context(id1)
    assert %{state: "done"} = Support.BasicTransitionWithChangeset.get_context(id2)

    Supervisor.stop(sup)
  end

  test "store_context_and_start_supervised - success" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1, state: "init"}

    assert {:ok, sup} = Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:ok, _} = GreenWorker.store_context_and_start_supervised(Support.NoActionWorker, ctx)

    assert %{schema: schema} = Support.NoActionWorker.get_config
    assert struct(schema, ctx) == Support.NoActionWorker.get_context(id1)

    Supervisor.stop(sup)
  end

  test "store_context_and_start_supervised - fail changeset validation" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1}

    assert {:ok, sup} = Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:error, _} = GreenWorker.store_context_and_start_supervised(Support.NoActionWorker, ctx)

    catch_exit(Support.NoActionWorker.get_context(id1))

    Supervisor.stop(sup)
  end

  defp wait_for(id, state) do
    receive do
      {^id, ^state} -> :ok
    after
      3_000 -> :nok
    end
  end
end
