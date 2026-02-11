defmodule Prettycore.Map.Estado do
  use Ecto.Schema

  @primary_key {:codigo_k, :integer, autogenerate: false}
  schema "map_estados" do
    field :descripcion, :string
  end
end
