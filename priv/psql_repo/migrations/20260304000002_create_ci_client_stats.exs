defmodule Prettycore.PsqlRepo.Migrations.CreateCiClientStats do
  use Ecto.Migration

  def change do
    create table(:ci_client_stats, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :client_code, :string, null: false
      add :dir_code, :string, null: false
      add :client_name, :string
      add :total_venta_anual, :float, default: 0.0
      add :cartera_vigente, :float, default: 0.0
      add :cartera_vencida, :float, default: 0.0
      add :enfriadores, :integer, default: 0
      add :clasificacion, :string        # A | B | C | D | nil
      add :ultimo_pedido_fecha, :string  # Guardamos como string del JSON
      add :fetched_at, :utc_datetime, null: false
      timestamps()
    end

    create unique_index(:ci_client_stats, [:client_code, :dir_code])
    create index(:ci_client_stats, [:total_venta_anual])
    create index(:ci_client_stats, [:cartera_vencida])
    create index(:ci_client_stats, [:clasificacion])
  end
end
