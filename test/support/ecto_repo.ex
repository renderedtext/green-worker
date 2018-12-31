defmodule Support.EctoRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :green_worker,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    # url = String.replace(System.get_env("DB_URL"), "PASSWORD", System.get_env("DB_PASSWORD"))
    url = "ecto://postgres:postgres@localhost/green_worker"

    {:ok, Keyword.put(config, :url, url)}
  end
end
