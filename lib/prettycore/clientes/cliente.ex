defmodule Prettycore.Clientes.Cliente do
  @moduledoc """
  Esquema para CTE_CLIENTE - Tabla de clientes
  """
  use Ecto.Schema

  @derive {
    Flop.Schema,
    filterable: [:ctecli_codigo_k, :ctecli_razonsocial, :ctecli_dencomercia, :ctecli_rfc],
    sortable: [:ctecli_codigo_k, :ctecli_razonsocial, :ctecli_dencomercia]
  }

  @primary_key {:ctecli_codigo_k, :string, autogenerate: false}
  @timestamps_opts [type: :naive_datetime]

  schema "CTE_CLIENTE" do
    field(:ctecli_razonsocial, :string)
    field(:ctecli_dencomercia, :string)
    field(:ctecli_rfc, :string)
    field(:ctecli_fechaalta, :naive_datetime)
    field(:ctecli_fechabaja, :naive_datetime)
    field(:ctecli_causabaja, :string)
    field(:ctecli_edocred, :integer)
    field(:ctecli_diascredito, :integer)
    field(:ctecli_limitecredi, :decimal)
    field(:ctecli_tipodefact, :integer)
    field(:ctecli_tipofacdes, :integer)
    field(:ctecli_tipopago, :string)
    field(:ctecli_creditoobs, :string)
    field(:ctetpo_codigo_k, :integer)
    field(:ctesca_codigo_k, :string)
    field(:ctepaq_codigo_k, :string)
    field(:ctereg_codigo_k, :string)
    field(:ctecad_codigo_k, :string)
    field(:ctecan_codigo_k, :string)
    field(:ctecli_generico, :integer)
    field(:cfgmon_codigo_k, :string)
    field(:ctecli_observaciones, :string)
    field(:systra_codigo_k, :string)
    field(:facadd_codigo_k, :string)
    field(:ctecli_fereceptor, :string)
    field(:ctecli_fereceptormail, :string)
    field(:ctepor_codigo_k, :string)
    field(:ctecli_tipodefacr, :integer)
    field(:condim_codigo_k, :string)
    field(:ctecli_cxcliq, :integer)
    field(:ctecli_nocta, :string)
    field(:ctecli_dscantimp, :integer)
    field(:ctecli_desglosaieps, :integer)
    field(:ctecli_periodorefac, :integer)
    field(:ctecli_contacto, :string)
    field(:cfgban_codigo_k, :string)
    field(:ctecli_cargaespecifica, :integer)
    field(:ctecli_caducidadmin, :integer)
    field(:ctecli_ctlsanitario, :integer)
    field(:ctecli_formapago, :string)
    field(:ctecli_metodopago, :string)
    field(:ctecli_regtrib, :string)
    field(:ctecli_pais, :string)
    field(:ctecli_factablero, :integer)
    field(:sat_uso_cfdi_k, :string)
    field(:ctecli_complemento, :string)
    field(:ctecli_aplicacanje, :integer)
    field(:ctecli_aplicadev, :integer)
    field(:ctecli_desglosakit, :integer)
    field(:faccom_codigo_k, :string)
    field(:ctecli_facgrupo, :integer)
    field(:facads_codigo_k, :string)
    field(:s_maqedo, :integer)
    field(:s_fecha, :naive_datetime)
    field(:s_fi, :naive_datetime)
    field(:s_guid, :string)
    field(:s_guidlog, :string)
    field(:s_usuario, :string)
    field(:s_usuariodb, :string)
    field(:s_guidnot, :string)

    # Asociaciones
    has_many(:direcciones, Prettycore.Clientes.Direccion, foreign_key: :ctecli_codigo_k)

    belongs_to(:canal, Prettycore.Clientes.Canal,
      foreign_key: :ctecan_codigo_k,
      references: :ctecan_codigo_k,
      define_field: false
    )

    belongs_to(:subcanal, Prettycore.Clientes.Subcanal,
      foreign_key: :ctesca_codigo_k,
      references: :ctesca_codigo_k,
      define_field: false
    )

    belongs_to(:cadena, Prettycore.Clientes.Cadena,
      foreign_key: :ctecad_codigo_k,
      references: :ctecad_codigo_k,
      define_field: false
    )

    belongs_to(:paquete_servicio, Prettycore.Clientes.PaqueteServicio,
      foreign_key: :ctepaq_codigo_k,
      references: :ctepaq_codigo_k,
      define_field: false
    )

    belongs_to(:regimen, Prettycore.Clientes.Regimen,
      foreign_key: :ctereg_codigo_k,
      references: :ctereg_codigo_k,
      define_field: false
    )
  end
end
