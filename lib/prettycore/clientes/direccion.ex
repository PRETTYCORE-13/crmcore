defmodule Prettycore.Clientes.Direccion do
  @moduledoc """
  Esquema para CTE_DIRECCION - Direcciones de clientes
  """
  use Ecto.Schema

  @primary_key false
  schema "CTE_DIRECCION" do
    field(:ctecli_codigo_k, :string, primary_key: true)
    field(:ctedir_codigo_k, :string, primary_key: true)
    field(:ctepfr_codigo_k, :string)
    field(:vtarut_codigo_k_pre, :string)
    field(:vtarut_codigo_k_ent, :string)
    field(:vtarut_codigo_k_aut, :string)
    field(:mapedo_codigo_k, :integer)
    field(:mapmun_codigo_k, :integer)
    field(:maploc_codigo_k, :integer)
    field(:map_x, :string)
    field(:map_y, :string)
    field(:ctedir_calle, :string)
    field(:ctedir_colonia, :string)
    field(:ctedir_callenumext, :string)
    field(:ctedir_callenumint, :string)
    field(:ctedir_telefono, :string)
    field(:ctedir_celular, :string)
    field(:ctedir_mail, :string)

    # Campos virtuales que no existen en CTE_DIRECCION pero se usan en el formulario
    field(:cfgreg_codigo_k, :string, virtual: true)
    field(:satexp_codigo_k, :string, virtual: true)
    field(:catind_codigo_k, :string, virtual: true)
    field(:catpfi_codigo_k, :string, virtual: true)
    field(:ctecli_cfdi_ver, :string, virtual: true)
    field(:cteclu_codigo_k, :string, virtual: true)
    field(:ctezni_codigo_k, :string, virtual: true)

    field(:ctedir_responsable, :string)
    field(:ctedir_calleentre1, :string)
    field(:ctedir_calleentre2, :string)
    field(:ctedir_cp, :string)

    # Rutas adicionales
    field(:vtarut_codigo_k_cob, :string)
    field(:vtarut_codigo_k_simpre, :string)
    field(:vtarut_codigo_k_siment, :string)
    field(:vtarut_codigo_k_simcob, :string)
    field(:vtarut_codigo_k_simaut, :string)
    field(:vtarut_codigo_k_sup, :string)

    # Configuración
    field(:condim_codigo_k, :string)
    field(:ctepaq_codigo_k, :string)
    field(:ctecor_codigo_k, :string)

    # Embarque
    field(:ctevie_codigo_k, :string)
    field(:ctesvi_codigo_k, :string)

    # SAT y CFDI 4.0
    field(:satcp_codigo_k, :string)
    field(:satcol_codigo_k, :string)
    field(:c_estado_k, :string)
    field(:c_municipio_k, :string)
    field(:c_localidad_k, :string)

    # Estrategia
    field(:cfgest_codigo_k, :string)

    # Flags y configuración
    field(:ctedir_tipofis, :integer)
    field(:ctedir_tipoent, :integer)
    field(:ctedir_ivafrontera, :integer)
    field(:ctedir_secuencia, :integer)
    field(:ctedir_secuenciaent, :integer)
    field(:ctedir_reqgeo, :integer)
    field(:ctedir_distancia, :decimal)
    field(:ctedir_novalidavencimiento, :integer)
    field(:ctedir_edocred, :integer)
    field(:ctedir_diascredito, :integer)
    field(:ctedir_limitecredi, :decimal)
    field(:ctedir_tipopago, :integer)
    field(:ctedir_tipodefacr, :integer)
    field(:s_maqedo, :integer)

    # Campos de sistema (s_*)
    field(:systra_codigo_k, :string)
    field(:ctedir_geoubicacion, :string)
    field(:ctedir_guidref, :string)
    field(:ctedir_teladicional, :string)
    field(:ctedir_mailadicional, :string)
    field(:ctedir_maildicional, :string)
    field(:ctedir_observaciones, :string)

    # Secuencias por día
    field(:ctedir_secuencialu, :integer)
    field(:ctedir_secuenciama, :integer)
    field(:ctedir_secuenciami, :integer)
    field(:ctedir_secuenciaju, :integer)
    field(:ctedir_secuenciavi, :integer)
    field(:ctedir_secuenciasa, :integer)
    field(:ctedir_secuenciado, :integer)
    field(:ctedir_secuenciaentlu, :integer)
    field(:ctedir_secuenciaentma, :integer)
    field(:ctedir_secuenciaentmi, :integer)
    field(:ctedir_secuenciaentju, :integer)
    field(:ctedir_secuenciaentvi, :integer)
    field(:ctedir_secuenciaentsa, :integer)
    field(:ctedir_secuenciaentdo, :integer)

    # Información adicional de dirección
    field(:ctedir_codigopostal, :string)
    field(:ctedir_municipio, :string)
    field(:ctedir_estado, :string)
    field(:ctedir_localidad, :string)
    field(:ctedir_creditoobs, :integer)

    # Razón social y denominación comercial en dirección
    field(:ctecli_razonsocial, :string)
    field(:ctecli_dencomercia, :string)

    belongs_to(:cliente, Prettycore.Clientes.Cliente,
      foreign_key: :ctecli_codigo_k,
      references: :ctecli_codigo_k,
      define_field: false
    )

    belongs_to(:patron_frecuencia, Prettycore.Clientes.PatronFrecuencia,
      foreign_key: :ctepfr_codigo_k,
      references: :ctepfr_codigo_k,
      define_field: false
    )

    belongs_to(:estado, Prettycore.Clientes.Estado,
      foreign_key: :mapedo_codigo_k,
      references: :mapedo_codigo_k,
      define_field: false
    )

    belongs_to(:municipio, Prettycore.Clientes.Municipio,
      foreign_key: :mapmun_codigo_k,
      references: :mapmun_codigo_k,
      define_field: false
    )

    belongs_to(:localidad, Prettycore.Clientes.Localidad,
      foreign_key: :maploc_codigo_k,
      references: :maploc_codigo_k,
      define_field: false
    )
  end
end
