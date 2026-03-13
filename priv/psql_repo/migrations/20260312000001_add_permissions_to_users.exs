defmodule Prettycore.PsqlRepo.Migrations.AddPermissionsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :permissions, {:array, :string}, default: ["inicio"]
    end
  end
end
