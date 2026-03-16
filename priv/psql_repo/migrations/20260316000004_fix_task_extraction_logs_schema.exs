defmodule Prettycore.PsqlRepo.Migrations.FixTaskExtractionLogsSchema do
  use Ecto.Migration

  def change do
    alter table(:task_extraction_logs) do
      add :duration_ms,   :integer
      add :response_code, :integer
      add :executed_at,   :utc_datetime
      add :updated_at,    :utc_datetime
    end

    # Copiar started_at → executed_at para no perder datos existentes
    execute(
      "UPDATE task_extraction_logs SET executed_at = started_at, updated_at = inserted_at",
      "SELECT 1"
    )

    alter table(:task_extraction_logs) do
      remove :started_at
      remove :finished_at
    end
  end
end
