defmodule AlternativeWorkerTest do
  use ExUnit.Case
  doctest GreenWorker

  alias Support.EctoRepo, as: Repo

  import TestHelpers, only: [start_family: 1]

  setup do
    assert {:ok, _} = Ecto.Adapters.SQL.query(Repo, "truncate table alternative cascade;")

    {:ok, %{}}
  end

  test "store_and_start_supervised - success" do
    id1 = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id_field: id1, state_field: "initial_state"}

    start_family(Support.AlternativeWorker)

    assert {:ok, _} = GreenWorker.store_and_start_supervised(Support.AlternativeWorker, ctx)

    assert %{store: store, cache: cache} = Support.AlternativeWorker.get_context!(id1)
    assert id1 == store.id_field
    assert "really_done" == store.state_field
    assert %{id: ^id1} = cache
  end

  test "automatic dynamic supervisor initialization" do
    id1 = "86781246-0847-0000-0000-123456789012"
    ctx1 = %{id_field: id1, state_field: "initial_state"}
    assert {:ok, _} = GreenWorker.store(Support.AlternativeWorker, ctx1)
    id2 = "86781246-0847-0000-0001-123456789012"
    ctx2 = %{id_field: id2, state_field: "initial_state"}
    assert {:ok, _} = GreenWorker.store(Support.AlternativeWorker, ctx2)

    start_family(Support.AlternativeWorker)

    assert "really_done" = Support.AlternativeWorker.get_context!(id1).store.state_field
    assert "really_done" = Support.AlternativeWorker.get_context!(id2).store.state_field
  end
end
