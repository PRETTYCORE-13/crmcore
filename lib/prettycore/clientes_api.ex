defmodule Prettycore.ClientesApi do
  @moduledoc """
  API client for managing clientes via REST API
  """

  alias Prettycore.EncodingUtils

  @url "http://ecore.ath.cx:1405/SP/EN_RESTHELPER/Clientes"

  @doc """
  Creates a new client via REST API.

  ## Parameters
    - cliente_data: Map with client data (from embedded schema)
    - password: User password for authentication

  ## Returns
    - {:ok, response_body} on success
    - {:error, reason} on failure
  """
  def crear_cliente(cliente_data, password) do
    # Transform embedded schema data to API format
    body =
      cliente_data
      |> transform_to_api_format()
      |> EncodingUtils.convert_map_to_utf8()

    headers = [
      {"authorization", "Bearer " <> password},
      {"content-type", "application/json"}
    ]

    case Req.post(@url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(resp_body, label: "crear_cliente ")
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(resp_body, label: "crear_cliente error body")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        IO.inspect(body, label: "crear_cliente ")
        IO.inspect(reason, label: "crear_cliente error body")
        {:error, reason}
    end
  end

  @doc false
  def transform_to_api_format(cliente_data) do
    direccion = Map.get(cliente_data, :direccion)

    %{
      "clientes" => [
        %{
          # Datos Básicos
          "CTECLI_CODIGO_K" => cliente_data.ctecli_codigo_k,
          "CTECLI_RAZONSOCIAL" => cliente_data.ctecli_razonsocial,
          "CTECLI_DENCOMERCIA" => cliente_data.ctecli_dencomercia,
          "CTECLI_RFC" => cliente_data.ctecli_rfc,
          "CTECLI_NOMBRE" => Map.get(cliente_data, :ctecli_nombre),
          "CTECLI_CONTACTO" => Map.get(cliente_data, :ctecli_contacto),
          "CTECLI_FERECEPTOR" => Map.get(cliente_data, :ctecli_fereceptor),
          "CTECLI_FERECEPTORMAIL" => cliente_data.ctecli_fereceptormail,
          "CTECLI_NOCTA" => cliente_data.ctecli_nocta,
          "CTECLI_FECHAALTA" => format_datetime(cliente_data.ctecli_fechaalta),
          "CTECLI_FECHABAJA" => format_datetime(Map.get(cliente_data, :ctecli_fechabaja)),
          "CTECLI_CAUSABAJA" => Map.get(cliente_data, :ctecli_causabaja),
          "CTECLI_OBSERVACIONES" => Map.get(cliente_data, :ctecli_observaciones),

          # Información de Crédito
          "CTECLI_EDOCRED" => cliente_data.ctecli_edocred,
          "CTECLI_DIASCREDITO" => cliente_data.ctecli_diascredito,
          "CTECLI_LIMITECREDI" => format_decimal(cliente_data.ctecli_limitecredi),
          "CTECLI_CREDITOOBS" => Map.get(cliente_data, :ctecli_creditoobs),

          # Clasificación (Obligatorios NOT NULL)
          "CTETPO_CODIGO_K" => cliente_data.ctetpo_codigo_k,
          "CTECAN_CODIGO_K" => cliente_data.ctecan_codigo_k,
          "CTESCA_CODIGO_K" => cliente_data.ctesca_codigo_k,
          "CTEREG_CODIGO_K" => cliente_data.ctereg_codigo_k,
          "SYSTRA_CODIGO_K" => cliente_data.systra_codigo_k,
          "CFGMON_CODIGO_K" => cliente_data.cfgmon_codigo_k,

          # Facturación (Catálogos SAT)
          "CTECLI_FORMAPAGO" => cliente_data.ctecli_formapago,
          "CTECLI_METODOPAGO" => cliente_data.ctecli_metodopago,
          "SAT_USO_CFDI_K" => cliente_data.sat_uso_cfdi_k,
          "CFGREG_CODIGO_K" => cliente_data.cfgreg_codigo_k,
          "CTECLI_REGTRIB" => Map.get(cliente_data, :ctecli_regtrib),
          "CTECLI_COMPLEMENTO" => Map.get(cliente_data, :ctecli_complemento),
          "CTECLI_COMPATIBILIDAD" => Map.get(cliente_data, :ctecli_compatibilidad),
          "CTECLI_PRVPORTEOFAC" => Map.get(cliente_data, :ctecli_prvporteofac),
          "CTECLI_ECOMMERCE" => Map.get(cliente_data, :ctecli_ecommerce),

          # Catálogos Opcionales (Foreign Keys)
          "CTEPAQ_CODIGO_K" => cliente_data.ctepaq_codigo_k,
          "FACADD_CODIGO_K" => Map.get(cliente_data, :facadd_codigo_k),
          "CTEPOR_CODIGO_K" => Map.get(cliente_data, :ctepor_codigo_k),
          "CONDIM_CODIGO_K" => Map.get(cliente_data, :condim_codigo_k),
          "CTECAD_CODIGO_K" => Map.get(cliente_data, :ctecad_codigo_k),
          "CFGBAN_CODIGO_K" => Map.get(cliente_data, :cfgban_codigo_k),
          "SYSEMP_CODIGO_K" => Map.get(cliente_data, :sysemp_codigo_k),
          "FACCOM_CODIGO_K" => Map.get(cliente_data, :faccom_codigo_k),
          "FACADS_CODIGO_K" => Map.get(cliente_data, :facads_codigo_k),
          "CTESEG_CODIGO_K" => Map.get(cliente_data, :cteseg_codigo_k),
          "CATIND_CODIGO_K" => cliente_data.catind_codigo_k,
          "CATPFI_CODIGO_K" => cliente_data.catpfi_codigo_k,
          "SATEXP_CODIGO_K" => cliente_data.satexp_codigo_k,
          "CTECLI_PAIS" => cliente_data.ctecli_pais,

          # Flags (Valores por defecto)
          "CTECLI_GENERICO" => cliente_data.ctecli_generico,
          "CTECLI_DSCANTIMP" => cliente_data.ctecli_dscantimp,
          "CTECLI_DESGLOSAIEPS" => cliente_data.ctecli_desglosaieps,
          "CTECLI_PERIODOREFAC" => Map.get(cliente_data, :ctecli_periodorefac, 0),
          "CTECLI_CARGAESPECIFICA" => Map.get(cliente_data, :ctecli_cargaespecifica, 0),
          "CTECLI_CADUCIDADMIN" => Map.get(cliente_data, :ctecli_caducidadmin, 0),
          "CTECLI_CTLSANITARIO" => Map.get(cliente_data, :ctecli_ctlsanitario, 0),
          "CTECLI_FACTABLERO" => cliente_data.ctecli_factablero,
          "CTECLI_APLICACANJE" => cliente_data.ctecli_aplicacanje,
          "CTECLI_APLICADEV" => cliente_data.ctecli_aplicadev,
          "CTECLI_DESGLOSAKIT" => cliente_data.ctecli_desglosakit,
          "CTECLI_FACGRUPO" => cliente_data.ctecli_facgrupo,
          "CTECLI_TIMBRACB" => Map.get(cliente_data, :ctecli_timbracb, 0),
          "CTECLI_NOVALIDAVENCIMIENTO" => Map.get(cliente_data, :ctecli_novalidavencimiento, 0),
          "CTECLI_CFDI_VER" => cliente_data.ctecli_cfdi_ver,
          "CTECLI_APLICAREGALO" => Map.get(cliente_data, :ctecli_aplicaregalo, 0),
          "CTECLI_NOACEPTAFRACCIONES" => Map.get(cliente_data, :ctecli_noaceptafracciones, 0),
          "CTECLI_CXCLIQ" => Map.get(cliente_data, :ctecli_cxcliq, 0),

          # Tipos de Facturación
          "CTECLI_TIPODEFACT" => cliente_data.ctecli_tipodefact,
          "CTECLI_TIPOFACDES" => Map.get(cliente_data, :ctecli_tipofacdes, 0),
          "CTECLI_TIPODEFACR" => Map.get(cliente_data, :ctecli_tipodefacr, 0),
          "CTECLI_TIPOPAGO" => Map.get(cliente_data, :ctecli_tipopago, "99"),

          # Sistema
          "S_MAQEDO" => cliente_data.s_maqedo,

          # Direcciones
          "direccion" => transform_direccion_to_array(direccion)
        }
      ]
    }
  end

  @doc false
  def transform_direccion_to_array(nil), do: []

  @doc false
  def transform_direccion_to_array(direccion) do
    [transform_direccion(direccion)]
  end

  @doc false
  def transform_direccion(nil), do: nil

  @doc false
  def transform_direccion(direccion) do
    %{
      # Identificación y Duplicados del Cliente
      "CTECLI_CODIGO_K" => Map.get(direccion, :ctecli_codigo_k),
      "CTEDIR_CODIGO_K" => direccion.ctedir_codigo_k,
      "CTECLI_RAZONSOCIAL" => Map.get(direccion, :ctecli_razonsocial),
      "CTECLI_DENCOMERCIA" => Map.get(direccion, :ctecli_dencomercia),

      # Tipos de Dirección
      "CTEDIR_TIPOFIS" => Map.get(direccion, :ctedir_tipofis, 1),
      "CTEDIR_TIPOENT" => Map.get(direccion, :ctedir_tipoent, 1),

      # Dirección Física
      "CTEDIR_CALLE" => direccion.ctedir_calle,
      "CTEDIR_CALLENUMEXT" => direccion.ctedir_callenumext,
      "CTEDIR_CALLENUMINT" => direccion.ctedir_callenumint,
      "CTEDIR_COLONIA" => direccion.ctedir_colonia,
      "CTEDIR_CALLEENTRE1" => Map.get(direccion, :ctedir_calleentre1),
      "CTEDIR_CALLEENTRE2" => Map.get(direccion, :ctedir_calleentre2),
      "CTEDIR_CP" => direccion.ctedir_cp,
      "CTEDIR_CODIGOPOSTAL" => Map.get(direccion, :ctedir_codigopostal, direccion.ctedir_cp),

      # Ubicación Geográfica
      "MAPEDO_CODIGO_K" => direccion.mapedo_codigo_k,
      "MAPMUN_CODIGO_K" => direccion.mapmun_codigo_k,
      "MAPLOC_CODIGO_K" => direccion.maploc_codigo_k,
      "MAP_X" => Map.get(direccion, :map_x),
      "MAP_Y" => Map.get(direccion, :map_y),
      "CTEDIR_GEOUBICACION" => Map.get(direccion, :ctedir_geoubicacion),
      "CTEDIR_REQGEO" => Map.get(direccion, :ctedir_reqgeo),

      # Ubicación Texto (duplicados)
      "CTEDIR_MUNICIPIO" => Map.get(direccion, :ctedir_municipio),
      "CTEDIR_ESTADO" => Map.get(direccion, :ctedir_estado),
      "CTEDIR_LOCALIDAD" => Map.get(direccion, :ctedir_localidad),

      # Contacto
      "CTEDIR_RESPONSABLE" => direccion.ctedir_responsable,
      "CTEDIR_TELEFONO" => direccion.ctedir_telefono,
      "CTEDIR_CELULAR" => direccion.ctedir_celular,
      "CTEDIR_TELADICIONAL" => Map.get(direccion, :ctedir_teladicional),
      "CTEDIR_MAIL" => direccion.ctedir_mail,
      "CTEDIR_MAILADICIONAL" => Map.get(direccion, :ctedir_mailadicional),
      "CTEDIR_MAILDICIONAL" => Map.get(direccion, :ctedir_maildicional),

      # Observaciones
      "CTEDIR_OBSERVACIONES" => Map.get(direccion, :ctedir_observaciones),

      # Rutas (FK → VTA_RUTA)
      "VTARUT_CODIGO_K_PRE" => Map.get(direccion, :vtarut_codigo_k_pre),
      "VTARUT_CODIGO_K_ENT" => Map.get(direccion, :vtarut_codigo_k_ent),
      "VTARUT_CODIGO_K_COB" => Map.get(direccion, :vtarut_codigo_k_cob),
      "VTARUT_CODIGO_K_AUT" => Map.get(direccion, :vtarut_codigo_k_aut),
      "VTARUT_CODIGO_K_SUP" => Map.get(direccion, :vtarut_codigo_k_sup),

      # Rutas Simulación
      "VTARUT_CODIGO_K_SIMPRE" => Map.get(direccion, :vtarut_codigo_k_simpre),
      "VTARUT_CODIGO_K_SIMENT" => Map.get(direccion, :vtarut_codigo_k_siment),
      "VTARUT_CODIGO_K_SIMCOB" => Map.get(direccion, :vtarut_codigo_k_simcob),
      "VTARUT_CODIGO_K_SIMAUT" => Map.get(direccion, :vtarut_codigo_k_simaut),

      # Secuencias de Visita (Preventa)
      "CTEDIR_SECUENCIA" => Map.get(direccion, :ctedir_secuencia, 0),
      "CTEDIR_SECUENCIALU" => Map.get(direccion, :ctedir_secuencialu),
      "CTEDIR_SECUENCIAMA" => Map.get(direccion, :ctedir_secuenciama),
      "CTEDIR_SECUENCIAMI" => Map.get(direccion, :ctedir_secuenciami),
      "CTEDIR_SECUENCIAJU" => Map.get(direccion, :ctedir_secuenciaju),
      "CTEDIR_SECUENCIAVI" => Map.get(direccion, :ctedir_secuenciavi),
      "CTEDIR_SECUENCIASA" => Map.get(direccion, :ctedir_secuenciasa),
      "CTEDIR_SECUENCIADO" => Map.get(direccion, :ctedir_secuenciado),

      # Secuencias de Entrega
      "CTEDIR_SECUENCIAENT" => Map.get(direccion, :ctedir_secuenciaent, 0),
      "CTEDIR_SECUENCIAENTLU" => Map.get(direccion, :ctedir_secuenciaentlu),
      "CTEDIR_SECUENCIAENTMA" => Map.get(direccion, :ctedir_secuenciaentma),
      "CTEDIR_SECUENCIAENTMI" => Map.get(direccion, :ctedir_secuenciaentmi),
      "CTEDIR_SECUENCIAENTJU" => Map.get(direccion, :ctedir_secuenciaentju),
      "CTEDIR_SECUENCIAENTVI" => Map.get(direccion, :ctedir_secuenciaentvi),
      "CTEDIR_SECUENCIAENTSA" => Map.get(direccion, :ctedir_secuenciaentsa),
      "CTEDIR_SECUENCIAENTDO" => Map.get(direccion, :ctedir_secuenciaentdo),

      # Catálogos de Ubicación
      "CTECLU_CODIGO_K" => Map.get(direccion, :cteclu_codigo_k),
      "CTECOR_CODIGO_K" => Map.get(direccion, :ctecor_codigo_k),
      "CTEZNI_CODIGO_K" => Map.get(direccion, :ctezni_codigo_k),
      "CTEPFR_CODIGO_K" => Map.get(direccion, :ctepfr_codigo_k),
      "CTEDIR_DISTANCIA" => Map.get(direccion, :ctedir_distancia, 1),

      # SAT y Vías
      "CTEVIE_CODIGO_K" => Map.get(direccion, :ctevie_codigo_k),
      "CTESVI_CODIGO_K" => Map.get(direccion, :ctesvi_codigo_k),
      "SATCOL_CODIGO_K" => Map.get(direccion, :satcol_codigo_k),
      "SATCP_CODIGO_K" => Map.get(direccion, :satcp_codigo_k),

      # Información de Crédito por Dirección
      "CTEDIR_EDOCRED" => Map.get(direccion, :ctedir_edocred, 0),
      "CTEDIR_DIASCREDITO" => Map.get(direccion, :ctedir_diascredito, 0),
      "CTEDIR_LIMITECREDI" => Map.get(direccion, :ctedir_limitecredi, 0),
      "CTEDIR_TIPOPAGO" => Map.get(direccion, :ctedir_tipopago, 0),
      "CTEDIR_CREDITOOBS" => Map.get(direccion, :ctedir_creditoobs, 0),
      "CTEDIR_TIPODEFACR" => Map.get(direccion, :ctedir_tipodefacr),
      "CTEDIR_NOVALIDAVENCIMIENTO" => Map.get(direccion, :ctedir_novalidavencimiento, 0),

      # Flags e IVA
      "CTEDIR_IVAFRONTERA" => Map.get(direccion, :ctedir_ivafrontera, 0),

      # Referencias y Configuración
      "SYSTRA_CODIGO_K" => Map.get(direccion, :systra_codigo_k, "FRCTE_DIRECCION"),
      "CONDIM_CODIGO_K" => Map.get(direccion, :condim_codigo_k),
      "CTEDIR_GUIDREF" => Map.get(direccion, :ctedir_guidref),
      "CTEPAQ_CODIGO_K" => Map.get(direccion, :ctepaq_codigo_k),
      "CFGEST_CODIGO_K" => Map.get(direccion, :cfgest_codigo_k, 0),

      # Campos Auxiliares C_*
      "C_LOCALIDAD_K" => Map.get(direccion, :c_localidad_k),
      "C_MUNICIPIO_K" => Map.get(direccion, :c_municipio_k),
      "C_ESTADO_K" => Map.get(direccion, :c_estado_k)
    }
  end

  @doc false
  def format_datetime(%NaiveDateTime{} = dt) do
    NaiveDateTime.to_iso8601(dt)
  end

  @doc false
  def format_datetime(nil), do: nil

  def format_datetime(value) do
    "#{value}"
  end

  @doc false
  def format_decimal(%Decimal{} = d) do
    Decimal.to_float(d)
  end

  @doc false
  def format_decimal(value) when is_number(value), do: value

  @doc false
  def format_decimal(nil), do: 0.0
end
