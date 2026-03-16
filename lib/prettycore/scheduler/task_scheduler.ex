defmodule Prettycore.Scheduler.TaskScheduler do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "task_schedulers" do
    field :name, :string
    field :description, :string
    field :cron_expression, :string
    field :url, :string
    field :method, :string, default: "GET"
    field :headers, :map, default: %{}
    field :body, :string
    field :target_table, :string
    field :enabled, :boolean, default: true
    field :last_run_at, :utc_datetime
    field :last_status, :string

    has_many :extraction_logs, Prettycore.Scheduler.ExtractionLog

    timestamps(type: :utc_datetime)
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :description, :cron_expression, :url, :method, :headers, :body, :target_table, :enabled])
    |> validate_required([:name, :cron_expression, :url, :target_table])
    |> validate_inclusion(:method, ["GET", "POST", "PUT"])
    |> validate_format(:target_table, ~r/^[a-z][a-z0-9_]*$/, message: "solo letras minúsculas, números y guiones bajos")
  end
end
