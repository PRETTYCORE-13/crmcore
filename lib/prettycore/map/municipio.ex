defmodule Prettycore.Map.Municipio do
  use Ecto.Schema

  @primary_key false
  schema "map_municipios" do
    field :estado_codigo_k, :integer, primary_key: true
    field :codigo_k, :integer, primary_key: true
    field :descripcion, :string
  end
end
