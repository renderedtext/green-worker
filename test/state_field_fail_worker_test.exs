defmodule StateFieldFailWorkerTest do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo
  alias Support.StateFieldFailWorker

  setup do
    assert {:ok, _} = Ecto.Adapters.SQL.query(Repo, "truncate table basic cascade;")

    {:ok, %{}}
  end

  test "GreenWorker error: change store without changing state field" do
    id = "86781246-0847-11e9-b6f4-482ae31ad2de"
    ctx = %{id: id, state: "init"}

    assert {:ok, sup} =
             Supervisor.start_link(StateFieldFailWorker.Supervisor, strategy: :one_for_one)

    Process.flag(:trap_exit, true)
    assert {:ok, pid} =
              GreenWorker.store_and_start_supervised(StateFieldFailWorker, ctx)

    Process.link(pid)

    assert_receive {:EXIT, ^pid, error}
    assert String.contains?(
      error, "ctx changed but ctx.store.@state_field did NOT")
  end
end
