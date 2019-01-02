defmodule GreenWorker.Internal do
  @moduledoc false

  def get_id(ctx, key), do: Map.get(ctx.stored, key)

  def load(query_term, schema, repo) do
    repo.get_by(schema, query_term)
  end

  def store(%{stored: stored}, %{stored: to_store}, changeset, repo) do
    case changeset do
      nil -> to_store
      {m, f} -> call_changeset(m, f, [stored, to_map(to_store)])
    end
    |> repo.update()
  end

  def call_changeset(m, f, [data, params]) do
    apply(m, f, [data, to_map(params)])
  end

  def get_all_non_finished_workers(schema, repo) do
    import Ecto.Query

    from(s in schema, where: s.state != "done")
    |> repo.all()
  end

  def name(module, id), do: :"#{module}_#{id}"

  defp to_map(%_{} = v), do: Map.from_struct(v)
  defp to_map(%{} = v), do: v
end
