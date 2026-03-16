defmodule Prettycore.Scheduler do
  @moduledoc """
  Context API para el módulo Scheduler / Extractor de Datos.
  Gestiona tareas programadas y sus logs de ejecución.
  """

  import Ecto.Query
  alias Prettycore.PsqlRepo
  alias Prettycore.Scheduler.{TaskScheduler, ExtractionLog}

  # ── Tareas ────────────────────────────────────────────────────

  def list_tasks do
    PsqlRepo.all(from t in TaskScheduler, order_by: [asc: t.name])
  end

  def list_enabled_tasks do
    PsqlRepo.all(from t in TaskScheduler, where: t.enabled == true, order_by: [asc: t.name])
  end

  def get_task!(id), do: PsqlRepo.get!(TaskScheduler, id)

  def create_task(attrs \\ %{}) do
    %TaskScheduler{}
    |> TaskScheduler.changeset(attrs)
    |> PsqlRepo.insert()
  end

  def update_task(%TaskScheduler{} = task, attrs) do
    task
    |> TaskScheduler.changeset(attrs)
    |> PsqlRepo.update()
  end

  def delete_task(%TaskScheduler{} = task), do: PsqlRepo.delete(task)

  def change_task(%TaskScheduler{} = task, attrs \\ %{}) do
    TaskScheduler.changeset(task, attrs)
  end

  def update_task_run_status(task_id, status) do
    PsqlRepo.update_all(
      from(t in TaskScheduler, where: t.id == ^task_id),
      set: [last_run_at: DateTime.utc_now(), last_status: status]
    )
  end

  # ── Logs ──────────────────────────────────────────────────────

  def list_logs_for_task(task_id, limit \\ 50) do
    PsqlRepo.all(
      from l in ExtractionLog,
        where: l.task_scheduler_id == ^task_id,
        order_by: [desc: l.executed_at],
        limit: ^limit
    )
  end

  def list_recent_logs(limit \\ 100) do
    PsqlRepo.all(
      from l in ExtractionLog,
        order_by: [desc: l.executed_at],
        limit: ^limit,
        preload: [:task_scheduler]
    )
  end

  def create_log(attrs) do
    %ExtractionLog{}
    |> Ecto.Changeset.cast(attrs, [
      :task_scheduler_id,
      :status,
      :records_inserted,
      :duration_ms,
      :response_code,
      :error_message,
      :executed_at
    ])
    |> Ecto.Changeset.validate_required([:task_scheduler_id, :status, :executed_at])
    |> PsqlRepo.insert()
  end

  def task_stats(task_id) do
    from(l in ExtractionLog, where: l.task_scheduler_id == ^task_id)
    |> PsqlRepo.aggregate(:count, :id)
  end
end
