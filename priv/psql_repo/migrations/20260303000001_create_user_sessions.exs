defmodule Prettycore.PsqlRepo.Migrations.CreateUserSessions do
  use Ecto.Migration

  def change do
    create table(:user_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :session_token, :string, null: false
      add :ip_address, :string
      add :user_agent, :string
      add :device_type, :string
      add :browser, :string
      add :os, :string
      add :last_seen_at, :utc_datetime
      add :logged_out_at, :utc_datetime

      timestamps()
    end

    create unique_index(:user_sessions, [:session_token])
    create index(:user_sessions, [:user_id])
    create index(:user_sessions, [:inserted_at])
  end
end
