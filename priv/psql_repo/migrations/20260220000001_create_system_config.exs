defmodule Prettycore.PsqlRepo.Migrations.CreateSystemConfig do
  use Ecto.Migration

  def change do
    create table(:system_config, primary_key: false) do
      add :id, :integer, primary_key: true
      add :usuario, :string
      add :instancia, :string
      add :token, :text
      add :url, :string
      add :foto, :string

      timestamps(type: :utc_datetime)
    end
  end
end
