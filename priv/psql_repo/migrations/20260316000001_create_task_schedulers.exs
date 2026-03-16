defmodule Prettycore.PsqlRepo.Migrations.CreateTaskSchedulers do
  use Ecto.Migration

  def change do
    create table(:task_schedulers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :cron_expression, :string, null: false
      add :url, :string, null: false
      add :method, :string, default: "GET"
      add :headers, :map, default: %{}
      add :body, :text
      add :target_table, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :last_run_at, :utc_datetime
      add :last_status, :string

      timestamps(type: :utc_datetime)
    end

    create index(:task_schedulers, [:enabled])
  end
end
