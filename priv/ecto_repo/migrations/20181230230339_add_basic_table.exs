defmodule GreenWorker.EctoRepo.Migrations.AddBasicTable do
  use Ecto.Migration

  def change do
    create table(:basic, primary_key: false) do
      add :id,                  :uuid,              primary_key: true
      add :state,               :string
      add :result,              :string
      add :result_reason,       :string
    end
  end
end
