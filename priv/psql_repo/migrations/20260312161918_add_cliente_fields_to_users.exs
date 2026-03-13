defmodule Prettycore.PsqlRepo.Migrations.AddClienteFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :cliente_codigo, :string
      add :dir_codigo, :string
    end
  end
end
