defmodule Support.BasicSchema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, []}
  schema "basic" do
    # field :id,              Ecto.UUID
    field(:state, :string)
    field(:result, :string)
    field(:result_reason, :string)
  end

  import Ecto.Changeset

  @required_fields ~w(id state)a

  def changeset(basic_type, params \\ %{}) do
    basic_type
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:id, name: :basic_pkey)
  end
end
