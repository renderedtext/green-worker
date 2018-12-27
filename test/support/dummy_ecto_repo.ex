defmodule Support.DummyEctoRepo do


  def get(schema, id) do
    {schema, id}
    |>IO.inspect(label: "WWWWWWWWWWWWW query")

    case id do
    "86781246-0847-11e9-b6f4-482ae31ad2de" ->
      struct(Support.BasicSchema, %{state: "init", id: "86781246-0847-11e9-b6f4-482ae31ad2de"})
    "c6d81146-0847-11e9-b6f4-482ae31adfd4" ->
      struct(Support.BasicSchema, %{state: "done", id: "c6d81146-0847-11e9-b6f4-482ae31adfd4", result: "passed"})

    "86781246-0847-0000-0000-123456789012" ->
      struct(Support.BasicSchema, %{state: "init", id: "86781246-0847-0000-0000-123456789012"})
    "86781246-0847-0000-0001-123456789012" ->
      struct(Support.BasicSchema, %{state: "done", id: "86781246-0847-0000-0001-123456789012"})

    _ ->
      nil
    end
  end

  def all(_query) do
    [
      struct(Support.BasicSchema, %{state: "init", id: "86781246-0847-0000-0000-123456789012"}),
      struct(Support.BasicSchema, %{state: "init", id: "86781246-0847-0000-0001-123456789012"}),
    ]
  end

  def update(changeset) do
    {:ok, changeset}
    |> IO.inspect(label: "AAAAAAAAAAAAAAAAAAAAAAAAAAA persisted changeset")
  end

  def insert(changeset),
    do: do_insert(changeset.valid?, changeset)
        |> IO.inspect(label: "BBBBBBBBBBBBBBBBBBBBBBBBBinsert persisted changeset")

  def do_insert(_valid = true, changeset), do: {:ok, changeset}
  def do_insert(_valid = false, changeset), do: {:error, changeset}
end
