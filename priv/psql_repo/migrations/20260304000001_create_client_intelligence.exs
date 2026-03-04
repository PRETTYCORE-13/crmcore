defmodule Prettycore.PsqlRepo.Migrations.CreateClientIntelligence do
  use Ecto.Migration

  def change do
    # Eventos: cada interacción de un usuario con un cliente
    create table(:ci_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_code, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :event_type, :string, null: false  # viewed | edited | exported | note_added
      add :metadata, :map, default: %{}
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:ci_events, [:client_code])
    create index(:ci_events, [:user_id])
    create index(:ci_events, [:inserted_at])
    create index(:ci_events, [:client_code, :inserted_at])

    # Scores: cache de métricas calculadas por cliente
    create table(:ci_scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_code, :string, null: false
      add :activity_score, :integer, default: 0       # 0-100
      add :view_count_30d, :integer, default: 0
      add :edit_count_30d, :integer, default: 0
      add :last_viewed_at, :utc_datetime
      add :last_edited_at, :utc_datetime
      add :computed_at, :utc_datetime
      timestamps()
    end

    create unique_index(:ci_scores, [:client_code])
  end
end
