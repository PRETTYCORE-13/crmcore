defmodule Prettycore.ClientesApi do

  alias Prettycore.EncodingUtils
  alias Prettycore.Api.Client

  def crear_cliente(cliente_data, password) do
    json_string = build_json_string(cliente_data)

    IO.puts("\n========== JSON ENVIADO AL API (CREAR) ==========")
    IO.puts(json_string)
    IO.puts("=========================================\n")

    headers = [
      {"authorization", "Bearer " <> password},
      {"content-type", "application/json"}
    ]

    case Req.post(Client.base_url() <> "/ClientesNew", body: json_string, headers: headers, receive_timeout: 60_000) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        IO.puts("\n========== RESPUESTA EXITOSA (#{status}) ==========")
        IO.inspect(resp_body, label: "RESPONSE BODY", pretty: true, limit: :infinity)
        IO.puts("===================================================\n")
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.puts("\n========== ERROR HTTP (#{status}) ==========")
        IO.inspect(resp_body, label: "ERROR BODY", pretty: true, limit: :infinity)
        IO.puts("============================================\n")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        IO.puts("\n========== ERROR DE CONEXIÓN ==========")
        IO.inspect(reason, label: "ERROR", pretty: true)
        IO.puts("========================================\n")
        {:error, reason}
    end
  end


  def editar_cliente(cliente_data, password) do
    json_string = build_json_string(cliente_data)

    IO.puts("\n========== JSON ENVIADO AL API (ACTUALIZAR) ==========")
    IO.puts(json_string)
    IO.puts("======================================================\n")

    headers = [
      {"authorization", "Bearer " <> password},
      {"content-type", "application/json"}
    ]


    case Req.post(Client.base_url() <> "/ClientesEdit", body: json_string, headers: headers, receive_timeout: 60_000) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        IO.puts("\n========== RESPUESTA EXITOSA (#{status}) ==========")
        IO.inspect(resp_body, label: "RESPONSE BODY", pretty: true, limit: :infinity)
        IO.puts("===================================================\n")
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.puts("\n========== ERROR HTTP (#{status}) ==========")
        IO.inspect(resp_body, label: "ERROR BODY", pretty: true, limit: :infinity)
        IO.puts("============================================\n")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        IO.puts("\n========== ERROR DE CONEXIÓN ==========")
        IO.inspect(reason, label: "ERROR", pretty: true)
        IO.puts("========================================\n")
        {:error, reason}
    end
  end

  def info_cliente(codigo, token) do
    body = Jason.encode!(%{"CTECLI_CODIGO_K" => codigo})

    IO.puts("\n========== API InfoCliente ==========")
    IO.puts("URL: #{Client.base_url()}/InfoCliente")
    IO.puts("Body: #{body}")
    IO.puts("=====================================\n")

    headers = [
      {"authorization", "Bearer " <> token},
      {"content-type", "application/json"}
    ]

    case Req.post(Client.base_url() <> "/InfoCliente", body: body, headers: headers, receive_timeout: 60_000) do
      {:ok, %Req.Response{status: status, body: [cliente | _]}} when status in 200..299 ->
        direcciones = Map.get(cliente, "Direcciones", [])
        cliente_sin_dirs = Map.delete(cliente, "Direcciones")

        IO.puts("\n========== InfoCliente OK (#{status}) ==========")
        IO.puts("Cliente: #{cliente_sin_dirs["CTECLI_CODIGO_K"]} - #{cliente_sin_dirs["CTECLI_RAZONSOCIAL"]}")
        IO.puts("Direcciones: #{length(direcciones)}")
        IO.puts("================================================\n")

        {:ok, %{cliente: cliente_sin_dirs, direcciones: direcciones}}

      {:ok, %Req.Response{status: status, body: []}} when status in 200..299 ->
        IO.puts("\n========== InfoCliente: NO ENCONTRADO ==========\n")
        {:error, :not_found}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        IO.puts("\n========== InfoCliente ERROR (#{status}) ==========")
        IO.inspect(resp_body, label: "ERROR BODY", pretty: true)
        IO.puts("==================================================\n")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        IO.puts("\n========== InfoCliente ERROR CONEXIÓN ==========")
        IO.inspect(reason, label: "ERROR", pretty: true)
        IO.puts("================================================\n")
        {:error, reason}
    end
  end

  @doc false
  def build_json_string(cliente_data) do
    direcciones = Map.get(cliente_data, :direcciones, [])

    cliente_json = [
      ~s("CTECLI_CODIGO_K":#{json_value(cliente_data.ctecli_codigo_k)}),
      ~s("CTECLI_RAZONSOCIAL":#{json_value(cliente_data.ctecli_razonsocial)}),
      ~s("CTECLI_DENCOMERCIA":#{json_value(cliente_data.ctecli_dencomercia)}),
      ~s("CTECLI_RFC":#{json_value(cliente_data.ctecli_rfc)}),
      ~s("CTECLI_FECHAALTA":#{json_value(format_datetime(cliente_data.ctecli_fechaalta))}),
      ~s("CTECLI_FECHABAJA":#{json_value(format_datetime(Map.get(cliente_data, :ctecli_fechabaja)))}),
      ~s("CTECLI_CAUSABAJA":#{json_value(Map.get(cliente_data, :ctecli_causabaja))}),
      ~s("CTECLI_EDOCRED":#{parse_integer(cliente_data.ctecli_edocred)}),
      ~s("CTECLI_DIASCREDITO":#{parse_integer(cliente_data.ctecli_diascredito)}),
      ~s("CTECLI_LIMITECREDI":#{format_decimal(cliente_data.ctecli_limitecredi)}),
      ~s("CTECLI_TIPODEFACT":#{parse_integer(cliente_data.ctecli_tipodefact)}),
      ~s("CTECLI_TIPOFACDES":#{parse_integer(Map.get(cliente_data, :ctecli_tipofacdes, 0))}),
      ~s("CTECLI_TIPOPAGO":#{json_value(Map.get(cliente_data, :ctecli_tipopago, "99"))}),
      ~s("CTECLI_CREDITOOBS":#{json_value(Map.get(cliente_data, :ctecli_creditoobs))}),
      ~s("CTETPO_CODIGO_K":#{json_value(Map.get(cliente_data, :ctetpo_codigo_k, "100"))}),
      ~s("CTECAN_CODIGO_K":#{json_value(cliente_data.ctecan_codigo_k)}),
      ~s("CTESCA_CODIGO_K":#{json_value(cliente_data.ctesca_codigo_k)}),
      ~s("CTEPAQ_CODIGO_K":#{json_value(Map.get(cliente_data, :ctepaq_codigo_k, "100"))}),
      ~s("CTEREG_CODIGO_K":#{json_value(cliente_data.ctereg_codigo_k)}),
      ~s("CTECAD_CODIGO_K":#{json_value(Map.get(cliente_data, :ctecad_codigo_k))}),
      ~s("CTECLI_GENERICO":#{parse_integer(cliente_data.ctecli_generico)}),
      ~s("CFGMON_CODIGO_K":#{json_value(Map.get(cliente_data, :cfgmon_codigo_k, "MXN"))}),
      ~s("CTECLI_OBSERVACIONES":#{json_value(Map.get(cliente_data, :ctecli_observaciones))}),
      ~s("SYSTRA_CODIGO_K":#{json_value(Map.get(cliente_data, :systra_codigo_k, "FRCTE_CLIENTE"))}),
      ~s("FACADD_CODIGO_K":#{json_value(Map.get(cliente_data, :facadd_codigo_k))}),
      ~s("CTECLI_FERECEPTOR":#{json_value(Map.get(cliente_data, :ctecli_fereceptor))}),
      ~s("CTECLI_FERECEPTORMAIL":#{json_value(Map.get(cliente_data, :ctecli_fereceptormail))}),
      ~s("CTEPOR_CODIGO_K":#{json_value(Map.get(cliente_data, :ctepor_codigo_k))}),
      ~s("CTECLI_TIPODEFACR":#{json_value(Map.get(cliente_data, :ctecli_tipodefacr))}),
      ~s("CONDIM_CODIGO_K":#{json_value(Map.get(cliente_data, :condim_codigo_k))}),
      ~s("CTECLI_CXCLIQ":#{json_value(Map.get(cliente_data, :ctecli_cxcliq))}),
      ~s("CTECLI_NOCTA":#{json_value(Map.get(cliente_data, :ctecli_nocta, 1))}),
      ~s("CTECLI_DSCANTIMP":#{parse_integer(cliente_data.ctecli_dscantimp)}),
      ~s("CTECLI_DESGLOSAIEPS":#{parse_integer(cliente_data.ctecli_desglosaieps)}),
      ~s("CTECLI_PERIODOREFAC":#{parse_integer(Map.get(cliente_data, :ctecli_periodorefac, 0))}),
      ~s("CTECLI_CONTACTO":#{json_value(Map.get(cliente_data, :ctecli_contacto))}),
      ~s("CFGBAN_CODIGO_K":#{json_value(Map.get(cliente_data, :cfgban_codigo_k))}),
      ~s("CTECLI_CARGAESPECIFICA":#{parse_integer(Map.get(cliente_data, :ctecli_cargaespecifica, 0))}),
      ~s("CTECLI_CADUCIDADMIN":#{parse_integer(Map.get(cliente_data, :ctecli_caducidadmin, 0))}),
      ~s("CTECLI_CTLSANITARIO":#{parse_integer(Map.get(cliente_data, :ctecli_ctlsanitario, 0))}),
      ~s("CTECLI_FORMAPAGO":#{json_value(Map.get(cliente_data, :ctecli_formapago, "01"))}),
      ~s("CTECLI_METODOPAGO":#{json_value(Map.get(cliente_data, :ctecli_metodopago, "PUE"))}),
      ~s("CTECLI_REGTRIB":#{json_value(Map.get(cliente_data, :ctecli_regtrib))}),
      ~s("CTECLI_PAIS":#{json_value(cliente_data.ctecli_pais)}),
      ~s("CTECLI_FACTABLERO":#{parse_integer(cliente_data.ctecli_factablero)}),
      ~s("SAT_USO_CFDI_K":#{json_value(cliente_data.sat_uso_cfdi_k)}),
      ~s("CTECLI_COMPLEMENTO":#{json_value(Map.get(cliente_data, :ctecli_complemento))}),
      ~s("CTECLI_APLICACANJE":#{parse_integer(cliente_data.ctecli_aplicacanje)}),
      ~s("CTECLI_APLICADEV":#{parse_integer(cliente_data.ctecli_aplicadev)}),
      ~s("CTECLI_DESGLOSAKIT":#{parse_integer(cliente_data.ctecli_desglosakit)}),
      ~s("FACCOM_CODIGO_K":#{json_value(Map.get(cliente_data, :faccom_codigo_k))}),
      ~s("CTECLI_FACGRUPO":#{parse_integer(cliente_data.ctecli_facgrupo)}),
      ~s("FACADS_CODIGO_K":#{json_value(Map.get(cliente_data, :facads_codigo_k))}),
      ~s("S_MAQEDO":#{parse_integer(cliente_data.s_maqedo)}),
      ~s("CTECLI_TIMBRACB":#{parse_integer(Map.get(cliente_data, :ctecli_timbracb, 0))}),
      ~s("SYSEMP_CODIGO_K":#{json_value(Map.get(cliente_data, :sysemp_codigo_k))}),
      ~s("CTECLI_NOVALIDAVENCIMIENTO":#{parse_integer(Map.get(cliente_data, :ctecli_novalidavencimiento, 0))}),
      ~s("CTECLI_COMPATIBILIDAD":#{json_value(Map.get(cliente_data, :ctecli_compatibilidad))}),
      ~s("SATEXP_CODIGO_K":#{json_value(cliente_data.satexp_codigo_k)}),
      ~s("CFGREG_CODIGO_K":#{json_value(cliente_data.cfgreg_codigo_k)}),
      ~s("CTECLI_CFDI_VER":#{parse_integer(cliente_data.ctecli_cfdi_ver)}),
      ~s("CTECLI_NOMBRE":#{json_value(Map.get(cliente_data, :ctecli_nombre))}),
      ~s("CTECLI_APLICAREGALO":#{parse_integer(Map.get(cliente_data, :ctecli_aplicaregalo, 0))}),
      ~s("CTECLI_PRVPORTEOFAC":#{json_value(Map.get(cliente_data, :ctecli_prvporteofac))}),
      ~s("CTECLI_NOACEPTAFRACCIONES":#{parse_integer(Map.get(cliente_data, :ctecli_noaceptafracciones, 0))}),
      ~s("CTESEG_CODIGO_K":#{json_value(Map.get(cliente_data, :cteseg_codigo_k))}),
      ~s("CTECLI_ECOMMERCE":#{json_value(Map.get(cliente_data, :ctecli_ecommerce))}),
      ~s("CATIND_CODIGO_K":#{json_value(Map.get(cliente_data, :catind_codigo_k, "3"))}),
      ~s("CATPFI_CODIGO_K":#{json_value(Map.get(cliente_data, :catpfi_codigo_k, "1"))}),
      ~s("direcciones":[#{Enum.map_join(direcciones, ",", fn dir -> build_direccion_json(dir, cliente_data) end)}])
    ]
    |> Enum.join(",")

    ~s({"clientes":[{#{cliente_json}}]})
  end

  @doc false
  defp build_direccion_json(direccion, cliente_data) do
    fields = [
      ~s("CTECLI_CODIGO_K":#{json_value(cliente_data.ctecli_codigo_k)}),
      ~s("CTEDIR_CODIGO_K":#{json_value(direccion.ctedir_codigo_k)}),
      ~s("CTECLI_RAZONSOCIAL":#{json_value(cliente_data.ctecli_razonsocial)}),
      ~s("CTECLI_DENCOMERCIA":#{json_value(cliente_data.ctecli_dencomercia)}),
      ~s("CTEDIR_TIPOFIS":#{parse_integer(Map.get(direccion, :ctedir_tipofis, "1"))}),
      ~s("CTEDIR_TIPOENT":#{parse_integer(Map.get(direccion, :ctedir_tipoent, "1"))}),
      ~s("CTEDIR_RESPONSABLE":#{json_value(direccion.ctedir_responsable)}),
      ~s("CTEDIR_TELEFONO":#{json_value(direccion.ctedir_telefono)}),
      ~s("CTEDIR_CALLE":#{json_value(direccion.ctedir_calle)}),
      ~s("CTEDIR_CALLENUMEXT":#{json_value(direccion.ctedir_callenumext)}),
      ~s("CTEDIR_CALLENUMINT":#{json_value(direccion.ctedir_callenumint)}),
      ~s("CTEDIR_COLONIA":#{json_value(direccion.ctedir_colonia)}),
      ~s("CTEDIR_CALLEENTRE1":#{json_value(Map.get(direccion, :ctedir_calleentre1))}),
      ~s("CTEDIR_CALLEENTRE2":#{json_value(Map.get(direccion, :ctedir_calleentre2))}),
      ~s("CTEDIR_CP":#{json_value(direccion.ctedir_cp)}),
      ~s("MAPEDO_CODIGO_K":#{json_value(direccion.mapedo_codigo_k)}),
      ~s("MAPMUN_CODIGO_K":#{json_value(direccion.mapmun_codigo_k)}),
      ~s("MAPLOC_CODIGO_K":#{json_value(direccion.maploc_codigo_k)}),
      ~s("MAP_X":#{json_value(Map.get(direccion, :map_x))}),
      ~s("MAP_Y":#{json_value(Map.get(direccion, :map_y))}),
      ~s("CTECLU_CODIGO_K":#{json_value(Map.get(direccion, :cteclu_codigo_k))}),
      ~s("CTECOR_CODIGO_K":#{json_value(Map.get(direccion, :ctecor_codigo_k))}),
      ~s("CTEZNI_CODIGO_K":#{json_value(Map.get(direccion, :ctezni_codigo_k))}),
      ~s("CTEDIR_OBSERVACIONES":#{json_value(Map.get(direccion, :ctedir_observaciones))}),
      ~s("CTEPFR_CODIGO_K":#{json_value(Map.get(direccion, :ctepfr_codigo_k))}),
      ~s("VTARUT_CODIGO_K_PRE":#{json_value(Map.get(direccion, :vtarut_codigo_k_pre))}),
      ~s("VTARUT_CODIGO_K_ENT":#{json_value(Map.get(direccion, :vtarut_codigo_k_ent))}),
      ~s("VTARUT_CODIGO_K_COB":#{json_value(Map.get(direccion, :vtarut_codigo_k_cob))}),
      ~s("VTARUT_CODIGO_K_AUT":#{json_value(Map.get(direccion, :vtarut_codigo_k_aut))}),
      ~s("CTEDIR_IVAFRONTERA":#{parse_integer(Map.get(direccion, :ctedir_ivafrontera, "0"))}),
      ~s("SYSTRA_CODIGO_K":#{json_value(Map.get(direccion, :systra_codigo_k, "FRCTE_DIRECCION"))}),
      ~s("CTEDIR_SECUENCIA":#{parse_integer(Map.get(direccion, :ctedir_secuencia, 0))}),
      ~s("CTEDIR_SECUENCIAENT":#{parse_integer(Map.get(direccion, :ctedir_secuenciaent, 0))}),
      ~s("CTEDIR_GEOUBICACION":#{json_value(Map.get(direccion, :ctedir_geoubicacion))}),
      ~s("VTARUT_CODIGO_K_SIMPRE":#{json_value(Map.get(direccion, :vtarut_codigo_k_simpre))}),
      ~s("VTARUT_CODIGO_K_SIMENT":#{json_value(Map.get(direccion, :vtarut_codigo_k_siment))}),
      ~s("VTARUT_CODIGO_K_SIMCOB":#{json_value(Map.get(direccion, :vtarut_codigo_k_simcob))}),
      ~s("VTARUT_CODIGO_K_SIMAUT":#{json_value(Map.get(direccion, :vtarut_codigo_k_simaut))}),
      ~s("CONDIM_CODIGO_K":#{json_value(Map.get(direccion, :condim_codigo_k))}),
      ~s("CTEDIR_CELULAR":#{json_value(direccion.ctedir_celular)}),
      ~s("CTEDIR_REQGEO":#{json_value(Map.get(direccion, :ctedir_reqgeo, 0))}),
      ~s("CTEDIR_GUIDREF":#{json_value(Map.get(direccion, :ctedir_guidref))}),
      ~s("CTEPAQ_CODIGO_K":#{json_value(Map.get(direccion, :ctepaq_codigo_k))}),
      ~s("VTARUT_CODIGO_K_SUP":#{json_value(Map.get(direccion, :vtarut_codigo_k_sup))}),
      ~s("CTEDIR_MAIL":#{json_value(direccion.ctedir_mail)}),
      ~s("CTEDIR_SECUENCIALU":#{parse_integer(Map.get(direccion, :ctedir_secuencialu, 0))}),
      ~s("CTEDIR_SECUENCIAMA":#{parse_integer(Map.get(direccion, :ctedir_secuenciama, 0))}),
      ~s("CTEDIR_SECUENCIAMI":#{parse_integer(Map.get(direccion, :ctedir_secuenciami, 0))}),
      ~s("CTEDIR_SECUENCIAJU":#{parse_integer(Map.get(direccion, :ctedir_secuenciaju, 0))}),
      ~s("CTEDIR_SECUENCIAVI":#{parse_integer(Map.get(direccion, :ctedir_secuenciavi, 0))}),
      ~s("CTEDIR_SECUENCIASA":#{parse_integer(Map.get(direccion, :ctedir_secuenciasa, 0))}),
      ~s("CTEDIR_SECUENCIADO":#{parse_integer(Map.get(direccion, :ctedir_secuenciado, 0))}),
      ~s("CTEDIR_SECUENCIAENTLU":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentlu, 0))}),
      ~s("CTEDIR_SECUENCIAENTMA":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentma, 0))}),
      ~s("CTEDIR_SECUENCIAENTMI":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentmi, 0))}),
      ~s("CTEDIR_SECUENCIAENTJU":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentju, 0))}),
      ~s("CTEDIR_SECUENCIAENTVI":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentvi, 0))}),
      ~s("CTEDIR_SECUENCIAENTSA":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentsa, 0))}),
      ~s("CTEDIR_SECUENCIAENTDO":#{parse_integer(Map.get(direccion, :ctedir_secuenciaentdo, 0))}),
      ~s("CTEDIR_CODIGOPOSTAL":#{json_value(Map.get(direccion, :ctedir_codigopostal, direccion.ctedir_cp))}),
      ~s("CTEDIR_MUNICIPIO":#{json_value(Map.get(direccion, :ctedir_municipio))}),
      ~s("CTEDIR_ESTADO":#{json_value(Map.get(direccion, :ctedir_estado))}),
      ~s("CTEDIR_LOCALIDAD":#{json_value(Map.get(direccion, :ctedir_localidad))}),
      ~s("CTEVIE_CODIGO_K":#{json_value(Map.get(direccion, :ctevie_codigo_k))}),
      ~s("CTESVI_CODIGO_K":#{json_value(Map.get(direccion, :ctesvi_codigo_k))}),
      ~s("SATCOL_CODIGO_K":#{json_value(Map.get(direccion, :satcol_codigo_k))}),
      ~s("CTEDIR_DISTANCIA":#{format_decimal(Map.get(direccion, :ctedir_distancia))}),
      ~s("CTEDIR_NOVALIDAVENCIMIENTO":#{parse_integer(Map.get(direccion, :ctedir_novalidavencimiento, 0))}),
      ~s("CTEDIR_EDOCRED":#{parse_integer(Map.get(direccion, :ctedir_edocred, 0))}),
      ~s("CTEDIR_DIASCREDITO":#{parse_integer(Map.get(direccion, :ctedir_diascredito, 0))}),
      ~s("CTEDIR_LIMITECREDI":#{format_decimal(Map.get(direccion, :ctedir_limitecredi))}),
      ~s("CTEDIR_TIPOPAGO":#{parse_integer(Map.get(direccion, :ctedir_tipopago, 0))}),
      ~s("CTEDIR_CREDITOOBS":#{parse_integer(Map.get(direccion, :ctedir_creditoobs, 0))}),
      ~s("CTEDIR_TIPODEFACR":#{json_value(Map.get(direccion, :ctedir_tipodefacr))}),
      ~s("CFGEST_CODIGO_K":#{parse_integer(Map.get(direccion, :cfgest_codigo_k, 0))}),
      ~s("CTEDIR_TELADICIONAL":#{json_value(Map.get(direccion, :ctedir_teladicional))}),
      ~s("CTEDIR_MAILADICIONAL":#{json_value(Map.get(direccion, :ctedir_mailadicional))}),
      ~s("C_LOCALIDAD_K":#{json_value(Map.get(direccion, :c_localidad_k))}),
      ~s("C_MUNICIPIO_K":#{json_value(Map.get(direccion, :c_municipio_k))}),
      ~s("C_ESTADO_K":#{json_value(Map.get(direccion, :c_estado_k))}),
      ~s("SATCP_CODIGO_K":#{json_value(Map.get(direccion, :satcp_codigo_k))}),
      ~s("CTEDIR_MAILDICIONAL":#{json_value(Map.get(direccion, :ctedir_maildicional))})
    ]
    |> Enum.join(",")

    "{#{fields}}"
  end

  @doc false
  defp json_value(nil), do: "null"
  defp json_value(value) when is_binary(value) do
    # Escapar caracteres especiales en strings
    escaped = value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")

    ~s("#{escaped}")
  end
  defp json_value(value) when is_number(value), do: to_string(value)
  defp json_value(value), do: to_string(value)

  @doc false
  def transform_to_api_format(cliente_data) do
    direcciones = Map.get(cliente_data, :direcciones, [])

    # Construir con Jason.OrderedObject para preservar el orden
    cliente = Jason.OrderedObject.new([
      {"CTECLI_CODIGO_K", cliente_data.ctecli_codigo_k},
      {"CTECLI_RAZONSOCIAL", cliente_data.ctecli_razonsocial},
      {"CTECLI_DENCOMERCIA", cliente_data.ctecli_dencomercia},
      {"CTECLI_RFC", cliente_data.ctecli_rfc},
      {"CTECLI_FECHAALTA", format_datetime(cliente_data.ctecli_fechaalta)},
      {"CTECLI_FECHABAJA", format_datetime(Map.get(cliente_data, :ctecli_fechabaja))},
      {"CTECLI_CAUSABAJA", Map.get(cliente_data, :ctecli_causabaja)},
      {"CTECLI_EDOCRED", parse_integer(cliente_data.ctecli_edocred)},
      {"CTECLI_DIASCREDITO", parse_integer(cliente_data.ctecli_diascredito)},
      {"CTECLI_LIMITECREDI", format_decimal(cliente_data.ctecli_limitecredi)},
      {"CTECLI_TIPODEFACT", parse_integer(cliente_data.ctecli_tipodefact)},
      {"CTECLI_TIPOFACDES", parse_integer(Map.get(cliente_data, :ctecli_tipofacdes, 0))},
      {"CTECLI_TIPOPAGO", Map.get(cliente_data, :ctecli_tipopago, "99")},
      {"CTECLI_CREDITOOBS", parse_integer(Map.get(cliente_data, :ctecli_creditoobs, 0))},
      {"CTETPO_CODIGO_K", cliente_data.ctetpo_codigo_k},
      {"CTECAN_CODIGO_K", cliente_data.ctecan_codigo_k},
      {"CTESCA_CODIGO_K", cliente_data.ctesca_codigo_k},
      {"CTEPAQ_CODIGO_K", cliente_data.ctepaq_codigo_k},
      {"CTEREG_CODIGO_K", cliente_data.ctereg_codigo_k},
      {"CTECAD_CODIGO_K", Map.get(cliente_data, :ctecad_codigo_k)},
      {"CTECLI_GENERICO", parse_integer(cliente_data.ctecli_generico)},
      {"CFGMON_CODIGO_K", cliente_data.cfgmon_codigo_k},
      {"CTECLI_OBSERVACIONES", Map.get(cliente_data, :ctecli_observaciones)},
      {"SYSTRA_CODIGO_K", cliente_data.systra_codigo_k},
      {"FACADD_CODIGO_K", Map.get(cliente_data, :facadd_codigo_k)},
      {"CTECLI_FERECEPTOR", Map.get(cliente_data, :ctecli_fereceptor)},
      {"CTECLI_FERECEPTORMAIL", cliente_data.ctecli_fereceptormail},
      {"CTEPOR_CODIGO_K", Map.get(cliente_data, :ctepor_codigo_k)},
      {"CTECLI_TIPODEFACR", parse_integer(Map.get(cliente_data, :ctecli_tipodefacr, 0))},
      {"CONDIM_CODIGO_K", Map.get(cliente_data, :condim_codigo_k)},
      {"CTECLI_CXCLIQ", parse_integer(Map.get(cliente_data, :ctecli_cxcliq, 0))},
      {"CTECLI_NOCTA", cliente_data.ctecli_nocta},
      {"CTECLI_DSCANTIMP", parse_integer(cliente_data.ctecli_dscantimp)},
      {"CTECLI_DESGLOSAIEPS", parse_integer(cliente_data.ctecli_desglosaieps)},
      {"CTECLI_PERIODOREFAC", parse_integer(Map.get(cliente_data, :ctecli_periodorefac, 0))},
      {"CTECLI_CONTACTO", Map.get(cliente_data, :ctecli_contacto)},
      {"CFGBAN_CODIGO_K", Map.get(cliente_data, :cfgban_codigo_k)},
      {"CTECLI_CARGAESPECIFICA", parse_integer(Map.get(cliente_data, :ctecli_cargaespecifica, 0))},
      {"CTECLI_CADUCIDADMIN", parse_integer(Map.get(cliente_data, :ctecli_caducidadmin, 0))},
      {"CTECLI_CTLSANITARIO", parse_integer(Map.get(cliente_data, :ctecli_ctlsanitario, 0))},
      {"CTECLI_FORMAPAGO", cliente_data.ctecli_formapago},
      {"CTECLI_METODOPAGO", cliente_data.ctecli_metodopago},
      {"CTECLI_REGTRIB", Map.get(cliente_data, :ctecli_regtrib)},
      {"CTECLI_PAIS", cliente_data.ctecli_pais},
      {"CTECLI_FACTABLERO", parse_integer(cliente_data.ctecli_factablero)},
      {"SAT_USO_CFDI_K", cliente_data.sat_uso_cfdi_k},
      {"CTECLI_COMPLEMENTO", Map.get(cliente_data, :ctecli_complemento)},
      {"CTECLI_APLICACANJE", parse_integer(cliente_data.ctecli_aplicacanje)},
      {"CTECLI_APLICADEV", parse_integer(cliente_data.ctecli_aplicadev)},
      {"CTECLI_DESGLOSAKIT", parse_integer(cliente_data.ctecli_desglosakit)},
      {"FACCOM_CODIGO_K", Map.get(cliente_data, :faccom_codigo_k)},
      {"CTECLI_FACGRUPO", parse_integer(cliente_data.ctecli_facgrupo)},
      {"FACADS_CODIGO_K", Map.get(cliente_data, :facads_codigo_k)},
      {"S_MAQEDO", parse_integer(cliente_data.s_maqedo)},
      {"CTECLI_TIMBRACB", parse_integer(Map.get(cliente_data, :ctecli_timbracb, 0))},
      {"SYSEMP_CODIGO_K", Map.get(cliente_data, :sysemp_codigo_k)},
      {"CTECLI_NOVALIDAVENCIMIENTO", parse_integer(Map.get(cliente_data, :ctecli_novalidavencimiento, 0))},
      {"CTECLI_COMPATIBILIDAD", Map.get(cliente_data, :ctecli_compatibilidad)},
      {"SATEXP_CODIGO_K", cliente_data.satexp_codigo_k},
      {"CFGREG_CODIGO_K", cliente_data.cfgreg_codigo_k},
      {"CTECLI_CFDI_VER", parse_integer(cliente_data.ctecli_cfdi_ver)},
      {"CTECLI_NOMBRE", Map.get(cliente_data, :ctecli_nombre)},
      {"CTECLI_APLICAREGALO", parse_integer(Map.get(cliente_data, :ctecli_aplicaregalo, 0))},
      {"CTECLI_PRVPORTEOFAC", Map.get(cliente_data, :ctecli_prvporteofac)},
      {"CTECLI_NOACEPTAFRACCIONES", parse_integer(Map.get(cliente_data, :ctecli_noaceptafracciones, 0))},
      {"CTESEG_CODIGO_K", Map.get(cliente_data, :cteseg_codigo_k)},
      {"CTECLI_ECOMMERCE", Map.get(cliente_data, :ctecli_ecommerce)},
      {"CATIND_CODIGO_K", cliente_data.catind_codigo_k},
      {"CATPFI_CODIGO_K", cliente_data.catpfi_codigo_k},
      {"direcciones", Enum.map(direcciones, &transform_direccion/1)}
    ])

    %{"clientes" => [cliente]}
  end

  @doc false
  def transform_direccion(nil), do: nil

  @doc false
  def transform_direccion(direccion) do
    # Usar Jason.OrderedObject para preservar el orden
    Jason.OrderedObject.new([
      {"CTEDIR_CODIGO_K", direccion.ctedir_codigo_k},
      {"CTEDIR_TIPOFIS", parse_integer(Map.get(direccion, :ctedir_tipofis, "1"))},
      {"CTEDIR_TIPOENT", parse_integer(Map.get(direccion, :ctedir_tipoent, "1"))},
      {"CTEDIR_RESPONSABLE", direccion.ctedir_responsable},
      {"CTEDIR_TELEFONO", direccion.ctedir_telefono},
      {"CTEDIR_CALLE", direccion.ctedir_calle},
      {"CTEDIR_CALLENUMEXT", direccion.ctedir_callenumext},
      {"CTEDIR_CALLENUMINT", direccion.ctedir_callenumint},
      {"CTEDIR_COLONIA", direccion.ctedir_colonia},
      {"CTEDIR_CALLEENTRE1", Map.get(direccion, :ctedir_calleentre1)},
      {"CTEDIR_CALLEENTRE2", Map.get(direccion, :ctedir_calleentre2)},
      {"CTEDIR_CP", direccion.ctedir_cp},
      {"MAPEDO_CODIGO_K", direccion.mapedo_codigo_k},
      {"MAPMUN_CODIGO_K", direccion.mapmun_codigo_k},
      {"MAPLOC_CODIGO_K", direccion.maploc_codigo_k},
      {"MAP_X", Map.get(direccion, :map_x)},
      {"MAP_Y", Map.get(direccion, :map_y)},
      {"CTECLU_CODIGO_K", Map.get(direccion, :cteclu_codigo_k)},
      {"CTECOR_CODIGO_K", Map.get(direccion, :ctecor_codigo_k)},
      {"CTEZNI_CODIGO_K", Map.get(direccion, :ctezni_codigo_k)},
      {"CTEDIR_OBSERVACIONES", Map.get(direccion, :ctedir_observaciones)},
      {"CTEPFR_CODIGO_K", Map.get(direccion, :ctepfr_codigo_k)},
      {"VTARUT_CODIGO_K_PRE", Map.get(direccion, :vtarut_codigo_k_pre)},
      {"VTARUT_CODIGO_K_ENT", Map.get(direccion, :vtarut_codigo_k_ent)},
      {"VTARUT_CODIGO_K_COB", Map.get(direccion, :vtarut_codigo_k_cob)},
      {"VTARUT_CODIGO_K_AUT", Map.get(direccion, :vtarut_codigo_k_aut)},
      {"CTEDIR_IVAFRONTERA", parse_integer(Map.get(direccion, :ctedir_ivafrontera, "0"))},
      {"SYSTRA_CODIGO_K", Map.get(direccion, :systra_codigo_k, "FRCTE_DIRECCION")},
      {"CTEDIR_SECUENCIA", parse_integer(Map.get(direccion, :ctedir_secuencia, 0))},
      {"CTEDIR_SECUENCIAENT", parse_integer(Map.get(direccion, :ctedir_secuenciaent, 0))},
      {"CTEDIR_GEOUBICACION", Map.get(direccion, :ctedir_geoubicacion)},
      {"VTARUT_CODIGO_K_SIMPRE", Map.get(direccion, :vtarut_codigo_k_simpre)},
      {"VTARUT_CODIGO_K_SIMENT", Map.get(direccion, :vtarut_codigo_k_siment)},
      {"VTARUT_CODIGO_K_SIMCOB", Map.get(direccion, :vtarut_codigo_k_simcob)},
      {"VTARUT_CODIGO_K_SIMAUT", Map.get(direccion, :vtarut_codigo_k_simaut)},
      {"CONDIM_CODIGO_K", Map.get(direccion, :condim_codigo_k)},
      {"CTEDIR_CELULAR", direccion.ctedir_celular},
      {"CTEDIR_REQGEO", Map.get(direccion, :ctedir_reqgeo, 0)},
      {"CTEDIR_GUIDREF", Map.get(direccion, :ctedir_guidref)},
      {"CTEPAQ_CODIGO_K", Map.get(direccion, :ctepaq_codigo_k)},
      {"VTARUT_CODIGO_K_SUP", Map.get(direccion, :vtarut_codigo_k_sup)},
      {"CTEDIR_MAIL", direccion.ctedir_mail},
      {"CTEDIR_SECUENCIALU", parse_integer(Map.get(direccion, :ctedir_secuencialu, 0))},
      {"CTEDIR_SECUENCIAMA", parse_integer(Map.get(direccion, :ctedir_secuenciama, 0))},
      {"CTEDIR_SECUENCIAMI", parse_integer(Map.get(direccion, :ctedir_secuenciami, 0))},
      {"CTEDIR_SECUENCIAJU", parse_integer(Map.get(direccion, :ctedir_secuenciaju, 0))},
      {"CTEDIR_SECUENCIAVI", parse_integer(Map.get(direccion, :ctedir_secuenciavi, 0))},
      {"CTEDIR_SECUENCIASA", parse_integer(Map.get(direccion, :ctedir_secuenciasa, 0))},
      {"CTEDIR_SECUENCIADO", parse_integer(Map.get(direccion, :ctedir_secuenciado, 0))},
      {"CTEDIR_SECUENCIAENTLU", parse_integer(Map.get(direccion, :ctedir_secuenciaentlu, 0))},
      {"CTEDIR_SECUENCIAENTMA", parse_integer(Map.get(direccion, :ctedir_secuenciaentma, 0))},
      {"CTEDIR_SECUENCIAENTMI", parse_integer(Map.get(direccion, :ctedir_secuenciaentmi, 0))},
      {"CTEDIR_SECUENCIAENTJU", parse_integer(Map.get(direccion, :ctedir_secuenciaentju, 0))},
      {"CTEDIR_SECUENCIAENTVI", parse_integer(Map.get(direccion, :ctedir_secuenciaentvi, 0))},
      {"CTEDIR_SECUENCIAENTSA", parse_integer(Map.get(direccion, :ctedir_secuenciaentsa, 0))},
      {"CTEDIR_SECUENCIAENTDO", parse_integer(Map.get(direccion, :ctedir_secuenciaentdo, 0))},
      {"CTEDIR_CODIGOPOSTAL", Map.get(direccion, :ctedir_codigopostal, direccion.ctedir_cp)},
      {"CTEDIR_MUNICIPIO", Map.get(direccion, :ctedir_municipio)},
      {"CTEDIR_ESTADO", Map.get(direccion, :ctedir_estado)},
      {"CTEDIR_LOCALIDAD", Map.get(direccion, :ctedir_localidad)},
      {"CTEVIE_CODIGO_K", Map.get(direccion, :ctevie_codigo_k)},
      {"CTESVI_CODIGO_K", Map.get(direccion, :ctesvi_codigo_k)},
      {"SATCOL_CODIGO_K", Map.get(direccion, :satcol_codigo_k)},
      {"CTEDIR_DISTANCIA", format_decimal(Map.get(direccion, :ctedir_distancia))},
      {"CTEDIR_NOVALIDAVENCIMIENTO", parse_integer(Map.get(direccion, :ctedir_novalidavencimiento, 0))},
      {"CTEDIR_EDOCRED", parse_integer(Map.get(direccion, :ctedir_edocred, 0))},
      {"CTEDIR_DIASCREDITO", parse_integer(Map.get(direccion, :ctedir_diascredito, 0))},
      {"CTEDIR_LIMITECREDI", format_decimal(Map.get(direccion, :ctedir_limitecredi))},
      {"CTEDIR_TIPOPAGO", parse_integer(Map.get(direccion, :ctedir_tipopago, 0))},
      {"CTEDIR_CREDITOOBS", parse_integer(Map.get(direccion, :ctedir_creditoobs, 0))},
      {"CTEDIR_TIPODEFACR", parse_integer(Map.get(direccion, :ctedir_tipodefacr, 0))},
      {"CFGEST_CODIGO_K", parse_integer(Map.get(direccion, :cfgest_codigo_k, 0))},
      {"CTEDIR_TELADICIONAL", Map.get(direccion, :ctedir_teladicional)},
      {"CTEDIR_MAILADICIONAL", Map.get(direccion, :ctedir_mailadicional)},
      {"C_LOCALIDAD_K", Map.get(direccion, :c_localidad_k)},
      {"C_MUNICIPIO_K", Map.get(direccion, :c_municipio_k)},
      {"C_ESTADO_K", Map.get(direccion, :c_estado_k)},
      {"SATCP_CODIGO_K", Map.get(direccion, :satcp_codigo_k)},
      {"CTEDIR_MAILDICIONAL", Map.get(direccion, :ctedir_maildicional)}
    ])
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

  @doc false
  def format_decimal(_), do: 0.0

  @doc false
  def parse_integer(value) when is_binary(value) do
    cond do
      value == "true" -> 1
      value == "false" -> 0
      true ->
        case Integer.parse(value) do
          {int, _} -> int
          :error -> 0
        end
    end
  end

  @doc false
  def parse_integer(value) when is_integer(value), do: value

  @doc false
  def parse_integer(value) when is_boolean(value), do: if(value, do: 1, else: 0)

  @doc false
  def parse_integer(nil), do: 0
end
