defmodule GreenWorker.Queries do
  @moduledoc false

  def read(query_term, schema, repo) do
    repo.get_by(schema, query_term)
  end

  def insert(to_store, _changeset = {m, f}, schema, repo) do
    call_changeset(m, f, [struct(schema), to_store])
    |> repo.insert()
  end

  def update(%{store: stored}, %{store: to_store}, _changeset = {m, f}, repo) do
    call_changeset(m, f, [stored, to_map(to_store)])
    |> repo.update()
  end

  def get_all_non_finished_workers(schema, repo, state_field_name, terminal_states) do
    import Ecto.Query

    from(s in schema, where: field(s, ^state_field_name) not in ^terminal_states)
    |> repo.all()
  end

  defp call_changeset(m, f, [data, params]) do
    apply(m, f, [data, to_map(params)])
  end

  defp to_map(v = %_{}), do: Map.from_struct(v)
  defp to_map(v = %{}), do: v
end
