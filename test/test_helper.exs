PubSub.start_link()

ExUnit.start()

defmodule TestHelpers do
  use ExUnit.Case

  def start_family(module_names) do
    children =
      module_names
      |> List.wrap()
      |> Enum.map(fn module_name ->
        {GreenWorker.Family.Supervisor, module_name}
      end)

    assert {:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)
  end
end
