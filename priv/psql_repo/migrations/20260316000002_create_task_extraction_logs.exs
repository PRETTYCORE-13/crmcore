defmodule Prettycore.PsqlRepo.Migrations.CreateTaskExtractionLogs do
  use Ecto.Migration

  def change do
    create table(:task_extraction_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :task_scheduler_id, references(:task_schedulers, on_delete: :delete_all, type: :binary_id), null: false
      add :status, :string, null: false
      add :records_inserted, :integer, default: 0
      add :duration_ms, :integer
      add :response_code, :integer
      add :error_message, :text
      add :executed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:task_extraction_logs, [:task_scheduler_id])
    create index(:task_extraction_logs, [:executed_at])
    create index(:task_extraction_logs, [:status])
  end
end
