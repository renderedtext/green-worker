defmodule Support.EctoRepo.Migrations.AddAlternativeTable do
  use Ecto.Migration

  def change do
    create table(:alternative, primary_key: false) do
      add :id_field,            :uuid,              primary_key: true
      add :state_field,         :string
    end
  end
end
