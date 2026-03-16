defmodule Prettycore.Scheduler.Worker do
  @moduledoc """
  Ejecutor HTTP + inserción de datos.
  - Realiza el request a la URL de la tarea.
  - Si la tabla destino no existe la crea automáticamente (columna `data` JSONB).
  - Inserta cada elemento de la respuesta como una fila JSONB.
  - Registra el resultado en task_extraction_logs.
  """

  require Logger

  alias Prettycore.Scheduler
  alias Prettycore.PsqlRepo

  def run(task_id) do
    start_ms = System.monotonic_time(:millisecond)
    task = Scheduler.get_task!(task_id)
    Logger.info("[Worker] Iniciando tarea: #{task.name}")

    {status, records, http_code, error} = execute(task)

    duration_ms = System.monotonic_time(:millisecond) - start_ms

    Scheduler.create_log(%{
      task_scheduler_id: task_id,
      status: status,
      records_inserted: records,
      duration_ms: duration_ms,
      response_code: http_code,
      error_message: error,
      executed_at: DateTime.utc_now()
    })

    Scheduler.update_task_run_status(task_id, status)

    if status == "ok" do
      Logger.info("[Worker] #{task.name} → #{records} registros en #{duration_ms}ms")
    else
      Logger.error("[Worker] #{task.name} falló: #{error}")
    end
  end

  # ── HTTP request ──────────────────────────────────────────────

  defp execute(task) do
    headers = task.headers || %{}
    method  = task.method |> String.downcase() |> String.to_existing_atom()

    req_opts = [headers: headers]
    req_opts = if task.body, do: Keyword.put(req_opts, :body, task.body), else: req_opts

    case apply(Req, method, [task.url, req_opts]) do
      {:ok, %Req.Response{status: code, body: body}} when code in 200..299 ->
        count = insert_data(task.target_table, body)
        {"ok", count, code, nil}

      {:ok, %Req.Response{status: code, body: body}} ->
        {"error", 0, code, "HTTP #{code}: #{inspect(body)}"}

      {:error, reason} ->
        {"error", 0, nil, inspect(reason)}
    end
  rescue
    e -> {"error", 0, nil, Exception.message(e)}
  end

  # ── Inserción dinámica ────────────────────────────────────────

  defp insert_data(table, rows) when is_list(rows) do
    ensure_table_exists(table)
    now = DateTime.utc_now()

    records = Enum.map(rows, fn row -> %{data: row, inserted_at: now} end)

    {count, _} = PsqlRepo.insert_all(table, records, on_conflict: :nothing)
    count
  end

  defp insert_data(table, map) when is_map(map), do: insert_data(table, [map])
  defp insert_data(table, other), do: insert_data(table, [%{raw: inspect(other)}])

  defp ensure_table_exists(table) do
    sql = """
    CREATE TABLE IF NOT EXISTS #{table} (
      id          BIGSERIAL PRIMARY KEY,
      data        JSONB,
      inserted_at TIMESTAMPTZ DEFAULT NOW()
    )
    """
    Ecto.Adapters.SQL.query!(PsqlRepo, sql, [])
  end
end
