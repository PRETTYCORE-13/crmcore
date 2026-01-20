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
    # Razón social del cliente
    field(:ctecli_razonsocial, :string)
    # Denominación comercial
    field(:ctecli_dencomercia, :string)
    # RFC (Registro Federal de Contribuyentes)
    field(:ctecli_rfc, :string)
    # Fecha de alta del cliente
    field(:ctecli_fechaalta, :naive_datetime)
    # Fecha de baja del cliente
    field(:ctecli_fechabaja, :naive_datetime)
    # Causa de baja del cliente
    field(:ctecli_causabaja, :string)
    # Estado de crédito (0=Sin crédito, 1=Con crédito)
    field(:ctecli_edocred, :integer)
    # Días de crédito otorgados
    field(:ctecli_diascredito, :integer)
    # Límite de crédito
    field(:ctecli_limitecredi, :decimal)
    # Tipo de factura (1=Normal, 2=Especial)
    field(:ctecli_tipodefact, :integer)
    # Tipo de factura de descuento
    field(:ctecli_tipofacdes, :integer)
    # Tipo de pago (Efectivo, Transferencia, etc.)
    field(:ctecli_tipopago, :string)
    # Observaciones sobre el crédito
    field(:ctecli_creditoobs, :string)
    # Código de tipo (FK a CTE_TIPO)
    field(:ctetpo_codigo_k, :integer)
    # Código de subcanal (FK a CTE_SUBCANAL)
    field(:ctesca_codigo_k, :string)
    # Código de paquete de servicio (FK a CTE_PAQUETE_SERVICIO)
    field(:ctepaq_codigo_k, :string)
    # Código de régimen (FK a CTE_REGIMEN)
    field(:ctereg_codigo_k, :string)
    # Código de cadena (FK a CTE_CADENA)
    field(:ctecad_codigo_k, :string)
    # Código de canal (FK a CTE_CANAL)
    field(:ctecan_codigo_k, :string)
    # Indica si es cliente genérico (0=No, 1=Sí)
    field(:ctecli_generico, :integer)
    # Código de moneda (FK a CFG_MONEDA)
    field(:cfgmon_codigo_k, :string)
    # Observaciones generales del cliente
    field(:ctecli_observaciones, :string)
    # Código de transaccion 
    field(:systra_codigo_k, :string)
    # Código de addenda de factura (FK a FAC_ADDENDA)
    field(:facadd_codigo_k, :string)
    # Forma de envío al receptor
    field(:ctecli_fereceptor, :string)
    # Email del receptor para facturación
    field(:ctecli_fereceptormail, :string)
    # Código de porteo (FK a CTE_PORTEO)
    field(:ctepor_codigo_k, :string)
    # Tipo de factura de remisión
    field(:ctecli_tipodefacr, :integer)
    # Código de dimensión contable (FK a CON_DIMENSION)
    field(:condim_codigo_k, :string)
    # Cuentas por cobrar liquidación (0=No, 1=Sí)
    field(:ctecli_cxcliq, :integer)
    # Número de cuenta contable
    field(:ctecli_nocta, :string)
    # Descuento en cantidad de impuestos (0=No, 1=Sí)
    field(:ctecli_dscantimp, :integer)
    # Desglosar IEPS en factura (0=No, 1=Sí)
    field(:ctecli_desglosaieps, :integer)
    # Periodo de refacturación en días
    field(:ctecli_periodorefac, :integer)
    # Nombre del contacto principal
    field(:ctecli_contacto, :string)
    # Código de banco (FK a CFG_BANCO)
    field(:cfgban_codigo_k, :string)
    # Carga específica (0=No, 1=Sí)
    field(:ctecli_cargaespecifica, :integer)
    # Caducidad mínima en días
    field(:ctecli_caducidadmin, :integer)
    # Control sanitario (0=No, 1=Sí)
    field(:ctecli_ctlsanitario, :integer)
    # Forma de pago SAT (Clave del catálogo SAT)
    field(:ctecli_formapago, :string)
    # Método de pago SAT (PUE, PPD)
    field(:ctecli_metodopago, :string)
    # Régimen tributario
    field(:ctecli_regtrib, :string)
    # País del cliente
    field(:ctecli_pais, :string)
    # Facturación tablero (0=No, 1=Sí)
    field(:ctecli_factablero, :integer)
    # Uso de CFDI SAT (Clave del catálogo SAT)
    field(:sat_uso_cfdi_k, :string)
    # Complemento de factura
    field(:ctecli_complemento, :string)
    # Aplica canje (0=No, 1=Sí)
    field(:ctecli_aplicacanje, :integer)
    # Aplica devoluciones (0=No, 1=Sí)
    field(:ctecli_aplicadev, :integer)
    # Desglosa kit en factura (0=No, 1=Sí)
    field(:ctecli_desglosakit, :integer)
    # Código de complemento de factura (FK a FAC_COMPLEMENTO)
    field(:faccom_codigo_k, :string)
    # Facturación por grupo (0=No, 1=Sí)
    field(:ctecli_facgrupo, :integer)
    # Código de addenda secundaria (FK a FAC_ADDENDA_SECUNDARIA)
    field(:facads_codigo_k, :string)
    # Máquina de edición (campo de sincronización)
    field(:s_maqedo, :integer)
    # Fecha de sincronización
    field(:s_fecha, :naive_datetime)
    # Fecha de inserción/sincronización
    field(:s_fi, :naive_datetime)
    # GUID único del registro
    field(:s_guid, :string)
    # GUID de log de sincronización
    field(:s_guidlog, :string)
    # Usuario que realizó la última modificación
    field(:s_usuario, :string)
    # Usuario de base de datos
    field(:s_usuariodb, :string)
    # GUID de notificación
    field(:s_guidnot, :string)

    # Campos adicionales que están en ClienteForm pero no en la tabla
    # (agregados virtualmente para facilitar la carga)
    # Timbra código de barras (0=No, 1=Sí) - Virtual
    field(:ctecli_timbracb, :integer, virtual: true, default: 0)
    # Código de empresa (FK a SYS_EMPRESA) - Virtual
    field(:sysemp_codigo_k, :string, virtual: true)
    # No valida vencimiento de productos (0=No, 1=Sí) - Virtual
    field(:ctecli_novalidavencimiento, :integer, virtual: true, default: 0)
    # Compatibilidad con versiones anteriores - Virtual
    field(:ctecli_compatibilidad, :string, virtual: true)
    # Código de exportación SAT (Clave del catálogo SAT) - Virtual
    field(:satexp_codigo_k, :string, virtual: true, default: "01")
    # Código de régimen fiscal (Clave del catálogo SAT) - Virtual
    field(:cfgreg_codigo_k, :string, virtual: true, default: "601")
    # Versión de CFDI (3.3=3, 4.0=4) - Virtual
    field(:ctecli_cfdi_ver, :integer, virtual: true, default: 4)
    # Nombre del cliente - Virtual
    field(:ctecli_nombre, :string, virtual: true)
    # Aplica regalo (0=No, 1=Sí) - Virtual
    field(:ctecli_aplicaregalo, :integer, virtual: true, default: 0)
    # Proveedor de porteo en factura - Virtual
    field(:ctecli_prvporteofac, :string, virtual: true)
    # No acepta fracciones (0=No, 1=Sí) - Virtual
    field(:ctecli_noaceptafracciones, :integer, virtual: true, default: 0)
    # Código de segmento (FK a CTE_SEGMENTO) - Virtual
    field(:cteseg_codigo_k, :string, virtual: true)
    # Cliente de e-commerce - Virtual
    field(:ctecli_ecommerce, :string, virtual: true)
    # Código de industria (FK a CAT_INDUSTRIA) - Virtual
    field(:catind_codigo_k, :string, virtual: true, default: "3")
    # Código de perfil fiscal (FK a CAT_PERFIL_FISCAL) - Virtual
    field(:catpfi_codigo_k, :string, virtual: true, default: "1")

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
