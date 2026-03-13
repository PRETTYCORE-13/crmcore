defmodule Prettycore.PsqlRepo.Migrations.CreateProductos do
  use Ecto.Migration

  def change do
    create table(:productos, primary_key: false) do
      add :codigo, :string, primary_key: true
      add :descripcion, :string
      add :desc_corta, :string
      add :marca, :string
      add :iva, :float, default: 0.0
      add :pzas_min_vta, :integer, default: 1
      add :activo, :boolean, default: true
      add :raw, :map

      timestamps(type: :utc_datetime)
    end

    create index(:productos, [:descripcion])
    create index(:productos, [:marca])
  end
end
