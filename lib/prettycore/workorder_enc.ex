defmodule Prettycore.Workorders.WorkorderEnc do
  use Ecto.Schema
  alias Prettycore.Workorders.WorkorderTipo

  @schema_prefix "dbo"
  @primary_key false

  @derive {
    Flop.Schema,
    filterable: [:sysudn, :estado, :usuario, :fecha],
    sortable: [:fecha, :sysudn, :estado, :folio],
    default_limit: 20,
    max_limit: 100
  }

  schema "XEN_WOKORDERENC" do
    field(:sysudn, :string, source: :SYSUDN_CODIGO_K)
    field(:systra, :string, source: :SYSTRA_CODIGO_K)
    field(:serie, :string, source: :WOKE_SERIE_K)
    field(:folio, :integer, source: :WOKE_FOLIO_K)
    field(:referencia, Latin1String, source: :WOKE_REFERENCIA)

    # Foreign key field must be defined when using define_field: false
    field(:tipo_id, :string, source: :WOKTPO_CODIGO_K)

    belongs_to(:tipo, WorkorderTipo,
      foreign_key: :tipo_id,
      references: :id,
      define_field: false
    )

    field(:estado, :integer, source: :S_MAQEDO)
    field(:descripcion, Latin1String, source: :WOKE_DESCRIPCION)
    field(:fecha, :naive_datetime, source: :S_FECHA)
    field(:usuario, Latin1String, source: :WOKE_USUARIO)
  end
end
