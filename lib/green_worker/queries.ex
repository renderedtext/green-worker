defmodule GreenWorker.Queries do

  def read(query_term, schema, repo) do
    repo.get_by(schema, query_term)
  end

  def insert(to_store, _changeset = {m, f}, schema, repo) do
    call_changeset(m, f, [struct(schema), to_store])
    |> repo.insert()
    |> IO.inspect(label: "DDDDDDDDDDDDDDDDDDD insert")
  end

  def update(%{stored: stored}, %{stored: to_store}, _changeset = {m, f}, repo) do
    call_changeset(m, f, [stored, to_map(to_store)])
    |> repo.update()
  end

  def get_all_non_finished_workers(schema, repo) do
    import Ecto.Query

    from(s in schema, where: s.state != "done")
    |> repo.all()
  end

  defp call_changeset(m, f, [data, params]) do
    apply(m, f, [data, to_map(params)])
  end

  defp to_map(%_{} = v), do: Map.from_struct(v)
  defp to_map(%{} = v), do: v
end
