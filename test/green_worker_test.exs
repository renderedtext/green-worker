defmodule GreenWorkerTest do
  use ExUnit.Case
  doctest GreenWorker

  test "greets the world" do
    assert GreenWorker.hello() == :world
  end
end
