defmodule Prettycore.Map.Localidad do
  use Ecto.Schema

  @primary_key false
  schema "map_localidades" do
    field :estado_codigo_k, :integer, primary_key: true
    field :municipio_codigo_k, :integer, primary_key: true
    field :codigo_k, :integer, primary_key: true
    field :descripcion, :string
    field :cp, :string
  end
end
