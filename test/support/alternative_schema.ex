defmodule Support.AlternativeSchema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id_field, Ecto.UUID, []}
  schema "alternative" do
    field(:state_field, :string)
  end

  import Ecto.Changeset

  @required_fields ~w(id_field state_field)a

  def cs(basic_type, params \\ %{}) do
    basic_type
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id, name: :alternative_pkey)
  end
end
