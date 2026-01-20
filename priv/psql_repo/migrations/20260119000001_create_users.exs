defmodule Prettycore.PsqlRepo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :email, :string
      add :password_hash, :string, null: false
      add :active, :boolean, default: true
      add :role, :string, default: "user"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
  end
end
