defmodule Prettycore.Scheduler.DynamicScheduler do
  @moduledoc """
  GenServer que carga las tareas habilitadas desde la base de datos
  al arrancar la aplicación y las registra en QuantumScheduler.
  """

  use GenServer
  require Logger

  alias Prettycore.Scheduler
  alias Prettycore.Scheduler.QuantumScheduler

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Recarga todas las tareas desde BD (útil tras crear/editar/borrar una tarea)."
  def reload_tasks do
    GenServer.cast(__MODULE__, :reload)
  end

  # ── Callbacks ─────────────────────────────────────────────────

  @impl true
  def init(_) do
    send(self(), :load_tasks)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:load_tasks, state) do
    load_all_tasks()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:reload, state) do
    QuantumScheduler.jobs()
    |> Enum.each(fn {name, _job} -> QuantumScheduler.delete_job(name) end)

    load_all_tasks()
    {:noreply, state}
  end

  # ── Private ───────────────────────────────────────────────────

  defp load_all_tasks do
    try do
      tasks = Scheduler.list_enabled_tasks()
      Logger.info("[DynamicScheduler] Registrando #{length(tasks)} tarea(s)")

      Enum.each(tasks, fn task ->
        schedule = Crontab.CronExpression.Parser.parse!(task.cron_expression)
        job_name = String.to_atom("task_#{task.id}")

        job =
          QuantumScheduler.new_job()
          |> Quantum.Job.set_name(job_name)
          |> Quantum.Job.set_schedule(schedule)
          |> Quantum.Job.set_task({Prettycore.Scheduler.Worker, :run, [task.id]})

        QuantumScheduler.add_job(job)
        Logger.info("[DynamicScheduler] ✓ #{task.name}  →  #{task.cron_expression}")
      end)
    rescue
      e ->
        Logger.error("[DynamicScheduler] Error al cargar tareas: #{inspect(e)}")
    end
  end
end
