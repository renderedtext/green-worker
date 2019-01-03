defmodule GreenWorkerTest do
  use ExUnit.Case
  doctest GreenWorker

  alias Support.EctoRepo, as: Repo

  setup do
    assert {:ok, _} = Ecto.Adapters.SQL.query(Repo, "truncate table basic cascade;")

    {:ok, %{}}
  end

  test "start_supervised - success" do
    assert {:ok, sup} = Supervisor.start_link(Support.Minimal.Supervisor, strategy: :one_for_one)

    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx1 = %{id: id1, state: "init"}
    assert {:ok, _} = GreenWorker.store(Support.Minimal, ctx1)
    id2 = "c6d81146-0847-11e9-b6f4-482ae31adfd4"
    ctx2 = %{id: id2, state: "done"}
    assert {:ok, _} = GreenWorker.store(Support.Minimal, ctx2)

    assert {:ok, pid} = GreenWorker.start_supervised(Support.Minimal, id1)
    assert is_pid(pid)
    assert {:ok, ^pid} = GreenWorker.start_supervised(Support.Minimal, id1)
    assert {:ok, _} = GreenWorker.start_supervised(Support.Minimal, id2)

    Supervisor.stop(sup)
  end

  test "start_supervised - state transitions" do
    PubSub.subscribe(self(), BasicTransition)

    assert {:ok, sup} =
             Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)

    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx1 = %{id: id1, state: "init"}
    assert {:ok, _} = GreenWorker.store(Support.BasicTransition, ctx1)

    assert {:ok, _} = GreenWorker.start_supervised(Support.BasicTransition, id1)

    wait_for(id1, "pending")
    assert "pending" = Support.BasicTransition.get_context!(id1).stored.state
    PubSub.publish(BasicTransitionToWorker, {id1, :can_advance})

    wait_for(id1, "done")
    assert "done" = Support.BasicTransition.get_context!(id1).stored.state

    Supervisor.stop(sup)
  end

  test "automatic dynamic supervisor initialization" do
    PubSub.subscribe(self(), BasicTransition)

    id1 = "86781246-0847-0000-0000-123456789012"
    ctx1 = %{id: id1, state: "init"}
    assert {:ok, _} = GreenWorker.store(Support.BasicTransitionWithChangeset, ctx1)
    id2 = "86781246-0847-0000-0001-123456789012"
    ctx2 = %{id: id2, state: "init"}
    assert {:ok, _} = GreenWorker.store(Support.BasicTransitionWithChangeset, ctx2)

    assert {:ok, sup} =
             Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)

    PubSub.publish(BasicTransitionToWorker, {id1, :can_advance})
    PubSub.publish(BasicTransitionToWorker, {id2, :can_advance})

    wait_for(id1, "done")
    wait_for(id2, "done")

    assert "done" = Support.BasicTransition.get_context!(id1).stored.state
    assert "done" = Support.BasicTransition.get_context!(id2).stored.state

    Supervisor.stop(sup)
  end

  test "start_supervised - start worker for non-existent id" do
    id1 = UUID.uuid1()

    assert {:ok, sup} =
             Supervisor.start_link(Support.BasicTransition.Supervisor, strategy: :one_for_one)

    assert {:error, {:bad_return_value, {:id_not_found, _}}} =
             GreenWorker.start_supervised(Support.BasicTransition, id1)

    Supervisor.stop(sup)
  end

  test "store_and_start_supervised - success" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1, state: "init"}

    assert {:ok, sup} =
             Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:ok, _} = GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    assert %{schema: schema} = Support.NoActionWorker.get_config()
    expected = struct(schema, ctx)
    assert expected = Support.NoActionWorker.get_context!(id1)

    Supervisor.stop(sup)
  end

  test "store_and_start_supervised - idempotent - if process is running" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1, state: "init"}

    assert {:ok, sup} =
             Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:ok, pid} =
             GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    assert {:ok, ^pid} =
             GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    assert %{schema: schema} = Support.NoActionWorker.get_config()
    expected = struct(schema, ctx)
    assert expected = Support.NoActionWorker.get_context!(id1)

    Supervisor.stop(sup)
  end

  test "store_and_start_supervised - idempotent - if process is not running" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1, state: "init"}

    assert {:ok, sup} =
             Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:ok, pid} =
             GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    GenServer.stop(pid)

    assert {:ok, pid2} =
             GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    assert pid != pid2

    assert %{schema: schema} = Support.NoActionWorker.get_config()
    expected = struct(schema, ctx)
    assert expected = Support.NoActionWorker.get_context!(id1)

    Supervisor.stop(sup)
  end

  test "store_and_start_supervised - fail changeset validation" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id1}

    assert {:ok, sup} =
             Supervisor.start_link(Support.NoActionWorker.Supervisor, strategy: :one_for_one)

    assert {:error, _} =
             GreenWorker.store_and_start_supervised(Support.NoActionWorker, ctx)

    catch_exit(Support.NoActionWorker.get_context!(id1))

    Supervisor.stop(sup)
  end

  test "get context from not-started process - id exists in DB" do
    id1 = "c6d81146-0847-11e9-b6f4-482ae31adfd4"
    ctx = %{id: id1, state: "done"}

    assert {:ok, sup} =
             Supervisor.start_link(
               Support.BasicTransitionWithChangeset.Supervisor,
               strategy: :one_for_one
             )

    assert {:ok, pid} =
             GreenWorker.store_and_start_supervised(
               Support.BasicTransitionWithChangeset,
               ctx
             )

    assert %{} = Support.BasicTransitionWithChangeset.get_context!(id1)
    assert {:ok, %GreenWorker.Ctx{cached: %{}, stored: %{}}} =
              GreenWorker.get_context(Support.BasicTransitionWithChangeset, id1)

    assert :ok = GenServer.stop(pid, :normal)
    refute Process.alive?(pid)

    catch_exit(Support.BasicTransitionWithChangeset.get_context!(id1))

    assert {:ok, %GreenWorker.Ctx{cached: %{}, stored: %{}}} =
              GreenWorker.get_context(Support.BasicTransitionWithChangeset, id1)
    assert %GreenWorker.Ctx{cached: %{}, stored: %{}} =
              Support.BasicTransitionWithChangeset.get_context!(id1)

    pid = GreenWorker.whereis(Support.BasicTransitionWithChangeset, id1)
    assert is_pid(pid)
    assert %GreenWorker.Ctx{cached: %{}, stored: %{}} =
              GenServer.call(pid, :get_context)

    Supervisor.stop(sup)
  end

  test "get context from not-started process - wrong id" do
    id = UUID.uuid1()
    ctx = %{id: id, state: "done"}

    assert {:ok, sup} =
             Supervisor.start_link(
               Support.BasicTransitionWithChangeset.Supervisor,
               strategy: :one_for_one
             )

    catch_exit(Support.BasicTransitionWithChangeset.get_context!(id))

    assert {:error, {_, {:id_not_found, _}}} =
             GreenWorker.get_context(Support.BasicTransitionWithChangeset, id)

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
