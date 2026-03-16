defmodule Prettycore.PsqlRepo.Migrations.FixTaskSchedulersSchema do
  use Ecto.Migration

  def change do
    alter table(:task_schedulers) do
      # Columnas que faltan en el schema nuevo
      add :cron_expression, :string
      add :url,             :string
      add :method,          :string, default: "GET"
      add :last_status,     :string
    end

    # Copiar datos de columnas viejas a las nuevas
    execute(
      "UPDATE task_schedulers SET url = api_url, method = http_method, last_status = last_run_status",
      "SELECT 1"
    )

    alter table(:task_schedulers) do
      remove :api_url
      remove :http_method
      remove :last_run_status
      remove :last_error
      remove :params
      remove :days
      remove :run_hour
      remove :run_minute
    end
  end
end
