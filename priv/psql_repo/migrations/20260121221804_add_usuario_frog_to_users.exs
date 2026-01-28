defmodule Prettycore.PsqlRepo.Migrations.AddUsuarioFrogToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :usuario_frog, :string
    end
  end
end
