defmodule Prettycore.Scheduler.ExtractionLog do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "task_extraction_logs" do
    field :status, :string
    field :records_inserted, :integer, default: 0
    field :duration_ms, :integer
    field :response_code, :integer
    field :error_message, :string
    field :executed_at, :utc_datetime

    belongs_to :task_scheduler, Prettycore.Scheduler.TaskScheduler

    timestamps(type: :utc_datetime)
  end
end
