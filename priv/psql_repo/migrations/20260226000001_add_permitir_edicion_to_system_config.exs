defmodule Prettycore.PsqlRepo.Migrations.AddPermitirEdicionToSystemConfig do
  use Ecto.Migration

  def change do
    alter table(:system_config) do
      add :permitir_edicion, :boolean, default: true, null: false
    end
  end
end
