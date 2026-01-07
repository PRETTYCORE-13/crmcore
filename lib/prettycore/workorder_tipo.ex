defmodule Prettycore.Workorders.WorkorderTipo do
  use Ecto.Schema

  @schema_prefix "dbo"
  @primary_key {:id, :string, source: :WOKTPO_CODIGO_K}

  schema "XEN_WOKORDERTIPO" do
    field(:descripcion, :string, source: :WOKTPO_DESCRIPCION)

    has_many(:encabezados, Prettycore.Workorders.WorkorderEnc,
      foreign_key: :tipo_id,
      references: :id
    )
  end
end
