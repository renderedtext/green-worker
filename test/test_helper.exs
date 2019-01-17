PubSub.start_link()

ExUnit.start()

defmodule TestHelpers do
  use ExUnit.Case

  alias Support.EctoRepo, as: Repo

  @doc """
  ## Ehamples
      start_family(Worker)
    or
      start_family([Worker1, Worker2, ...])
  """
  def start_family(module_names) do
    children =
      module_names
      |> List.wrap()
      |> Enum.map(fn module_name ->
        {GreenWorker.Family.Supervisor, module_name}
      end)
      |> Enum.each(fn child -> start_supervised!(child) end)
  end

  def truncate_db do
    {:ok, _} = Ecto.Adapters.SQL.query(Repo, "truncate table basic cascade;")
    {:ok, _} = Ecto.Adapters.SQL.query(Repo, "truncate table alternative cascade;")
  end
end
