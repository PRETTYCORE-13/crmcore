defmodule Prettycore.Workorders.WorkorderDet do
  use Ecto.Schema

  @primary_key false
  @schema_prefix "dbo"

  schema "XEN_WOKORDERDET" do
    field(:sysudn, :string, source: :SYSUDN_CODIGO_K)
    field(:systra, :string, source: :SYSTRA_CODIGO_K)
    field(:serie, :string, source: :WOKE_SERIE_K)
    field(:folio, :string, source: :WOKE_FOLIO_K)
    field(:concepto, :integer, source: :WOKD_RENGLON_K)
    field(:image_url, :string, source: :WOKD_IMAGEN)
  end
end
