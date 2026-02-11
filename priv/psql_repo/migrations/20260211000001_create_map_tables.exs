defmodule Prettycore.PsqlRepo.Migrations.CreateMapTables do
  use Ecto.Migration

  def change do
    # Estados (entidades federativas)
    create table(:map_estados, primary_key: false) do
      add :codigo_k, :integer, primary_key: true, null: false
      add :descripcion, :string, null: false
    end

    # Municipios (por estado)
    create table(:map_municipios, primary_key: false) do
      add :estado_codigo_k, :integer, null: false
      add :codigo_k, :integer, null: false
      add :descripcion, :string, null: false
    end

    create unique_index(:map_municipios, [:estado_codigo_k, :codigo_k])
    create index(:map_municipios, [:estado_codigo_k])

    # Localidades (por estado + municipio)
    create table(:map_localidades, primary_key: false) do
      add :estado_codigo_k, :integer, null: false
      add :municipio_codigo_k, :integer, null: false
      add :codigo_k, :integer, null: false
      add :descripcion, :string, null: false
      add :cp, :string
    end

    create unique_index(:map_localidades, [:estado_codigo_k, :municipio_codigo_k, :codigo_k])
    create index(:map_localidades, [:estado_codigo_k, :municipio_codigo_k])
    create index(:map_localidades, [:cp])
  end
end
