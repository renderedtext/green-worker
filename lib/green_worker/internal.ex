defmodule GreenWorker.Internal do
  @moduledoc false

  def get_id(ctx, key), do: Map.get(ctx, key)

  def load_context(query_term, schema, repo) do
    repo.get_by(schema, query_term)
  end

  def store_context(ctx, new_ctx, changeset, repo) do
    case changeset do
      nil -> new_ctx

      {m, f} -> call_changeset(m, f, [ctx, to_map(new_ctx)])
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
