defmodule Prettycore.Clientes do
  @moduledoc """
  Contexto para gestión de clientes
  """
  import Ecto.Query, warn: false
  alias Prettycore.Repo

  alias Prettycore.Clientes.{
    Cliente,
    Direccion,
    PatronFrecuencia,
    Canal,
    Subcanal,
    Cadena,
    PaqueteServicio,
    Regimen,
    Estado,
    Municipio,
    Localidad,
    Ruta
  }

  # Función helper para convertir Latin-1 a UTF-8
  defp fix_encoding(nil), do: nil

  defp fix_encoding(str) when is_binary(str) do
    case :unicode.characters_to_binary(str, :latin1, :utf8) do
      {:error, _, _} -> str
      result -> result
    end
  end

  defp fix_encoding(value), do: value

  # Limpia la codificación de todos los campos string en un map
  defp fix_map_encoding(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, fix_encoding(v)} end)
  end

  # Convierte tipos de coordenadas para compatibilidad
  defp fix_types(cliente) do
    Map.merge(cliente, %{
      map_x: safe_to_string(Map.get(cliente, :map_x)),
      map_y: safe_to_string(Map.get(cliente, :map_y))
    })
  end

  @doc """
  Lista clientes con todos sus datos relacionados.

  ## Parámetros
    * `sysudn_codigo_k` - Código de unidad de negocio
    * `vtarut_codigo_k_ini` - Ruta inicial
    * `vtarut_codigo_k_fin` - Ruta final

  ## Ejemplos
      iex> list_clientes_completo("100", "001", "999")
      [%{...}, ...]
  """
  def list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin) do
    query =
      from(c in Cliente,
        left_join: d in Direccion,
        on: c.ctecli_codigo_k == d.ctecli_codigo_k,
        left_join: pf in PatronFrecuencia,
        on: d.ctepfr_codigo_k == pf.ctepfr_codigo_k,
        left_join: can in Canal,
        on: c.ctecan_codigo_k == can.ctecan_codigo_k,
        left_join: sca in Subcanal,
        on:
          can.ctecan_codigo_k == sca.ctecan_codigo_k and c.ctesca_codigo_k == sca.ctesca_codigo_k,
        left_join: cad in Cadena,
        on: c.ctecad_codigo_k == cad.ctecad_codigo_k,
        left_join: paq in PaqueteServicio,
        on: c.ctepaq_codigo_k == paq.ctepaq_codigo_k,
        left_join: reg in Regimen,
        on: c.ctereg_codigo_k == reg.ctereg_codigo_k,
        left_join: edo in Estado,
        on: d.mapedo_codigo_k == edo.mapedo_codigo_k,
        left_join: mun in Municipio,
        on: d.mapedo_codigo_k == mun.mapedo_codigo_k and d.mapmun_codigo_k == mun.mapmun_codigo_k,
        left_join: loc in Localidad,
        on:
          d.mapedo_codigo_k == loc.mapedo_codigo_k and
            d.mapmun_codigo_k == loc.mapmun_codigo_k and
            d.maploc_codigo_k == loc.maploc_codigo_k,
        left_join: ruta in Ruta,
        on: ruta.vtarut_codigo_k in [d.vtarut_codigo_k_pre, d.vtarut_codigo_k_aut],
        where: c.s_maqedo == 10,
        where:
          (d.vtarut_codigo_k_pre >= ^vtarut_codigo_k_ini and
             d.vtarut_codigo_k_pre <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_ent >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_ent <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_aut >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_aut <= ^vtarut_codigo_k_fin),
        where: ruta.sysudn_codigo_k == ^sysudn_codigo_k,
        distinct: true,
        order_by: [asc: c.ctecli_codigo_k],
        select: %{
          # Estatus calculado
          estatus:
            fragment(
              "CASE WHEN ? = 10 THEN '---ACTIVO---' WHEN ? = 30 THEN '---PROSPECTO---' ELSE '---BAJA---' END",
              c.s_maqedo,
              c.s_maqedo
            ),

          # Datos de ruta
          udn: ruta.sysudn_codigo_k,
          preventa: d.vtarut_codigo_k_pre,
          entrega: d.vtarut_codigo_k_ent,
          autoventa: d.vtarut_codigo_k_aut,

          # Identificadores dirección
          ctepfr_codigo_k: d.ctepfr_codigo_k,
          ctedir_codigo_k: d.ctedir_codigo_k,

          # RFC
          rfc: c.ctecli_rfc,

          # Catálogos concatenados (convertir a string, NULL si están vacíos)
          frecuencia: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", pf.ctepfr_codigo_k, pf.ctepfr_descipcion),
          canal: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", can.ctecan_codigo_k, can.ctecan_descripcion),
          subcanal: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", sca.ctesca_codigo_k, sca.ctesca_descripcion),
          cadena: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", cad.ctecad_codigo_k, cad.ctecad_dcomercial),
          paquete_serv: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", paq.ctepaq_codigo_k, paq.ctepaq_descripcion),
          regimen: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", reg.ctereg_codigo_k, reg.ctereg_descripcion),

          # Ubicación concatenada (convertir a string, NULL si están vacíos)
          estado: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", edo.mapedo_codigo_k, edo.mapedo_descripcion),
          municipio: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", mun.mapmun_codigo_k, mun.mapmun_descripcion),
          localidad: fragment("NULLIF(CAST(CONCAT(?, '-', ?) AS VARCHAR(255)), '0')", loc.maploc_codigo_k, loc.maploc_descripcion),

          # Coordenadas (convertir a string ya que son latitud/longitud)
          map_x: fragment("CAST(? AS VARCHAR(50))", d.map_x),
          map_y: fragment("CAST(? AS VARCHAR(50))", d.map_y),

          # Dirección física
          ctedir_calle: d.ctedir_calle,
          ctedir_colonia: d.ctedir_colonia,
          ctedir_callenumext: d.ctedir_callenumext,
          ctedir_callenumint: d.ctedir_callenumint,
          ctedir_telefono: d.ctedir_telefono,
          ctedir_responsable: d.ctedir_responsable,
          ctedir_calleentre1: d.ctedir_calleentre1,
          ctedir_calleentre2: d.ctedir_calleentre2,
          ctedir_cp: d.ctedir_cp,

          # Todos los campos del cliente
          ctecli_codigo_k: c.ctecli_codigo_k,
          ctecli_razonsocial: c.ctecli_razonsocial,
          ctecli_dencomercia: c.ctecli_dencomercia,
          ctecli_fechaalta: c.ctecli_fechaalta,
          ctecli_fechabaja: c.ctecli_fechabaja,
          ctecli_causabaja: c.ctecli_causabaja,
          ctecli_edocred: c.ctecli_edocred,
          ctecli_diascredito: c.ctecli_diascredito,
          ctecli_limitecredi: c.ctecli_limitecredi,
          ctecli_tipodefact: c.ctecli_tipodefact,
          ctecli_tipofacdes: c.ctecli_tipofacdes,
          ctecli_tipopago: c.ctecli_tipopago,
          ctecli_creditoobs: c.ctecli_creditoobs,
          ctetpo_codigo_k: c.ctetpo_codigo_k,
          ctesca_codigo_k: c.ctesca_codigo_k,
          ctepaq_codigo_k: c.ctepaq_codigo_k,
          ctereg_codigo_k: c.ctereg_codigo_k,
          ctecad_codigo_k: c.ctecad_codigo_k,
          ctecli_generico: c.ctecli_generico,
          cfgmon_codigo_k: c.cfgmon_codigo_k,
          ctecli_observaciones: c.ctecli_observaciones,
          systra_codigo_k: c.systra_codigo_k,
          facadd_codigo_k: c.facadd_codigo_k,
          ctecli_fereceptor: c.ctecli_fereceptor,
          ctecli_fereceptormail: c.ctecli_fereceptormail,
          ctepor_codigo_k: c.ctepor_codigo_k,
          ctecli_tipodefacr: c.ctecli_tipodefacr,
          condim_codigo_k: c.condim_codigo_k,
          ctecli_cxcliq: c.ctecli_cxcliq,
          ctecli_nocta: c.ctecli_nocta,
          ctecli_dscantimp: c.ctecli_dscantimp,
          ctecli_desglosaieps: c.ctecli_desglosaieps,
          ctecli_periodorefac: c.ctecli_periodorefac,
          ctecli_contacto: c.ctecli_contacto,
          cfgban_codigo_k: c.cfgban_codigo_k,
          ctecli_cargaespecifica: c.ctecli_cargaespecifica,
          ctecli_caducidadmin: c.ctecli_caducidadmin,
          ctecli_ctlsanitario: c.ctecli_ctlsanitario,
          ctecli_formapago: c.ctecli_formapago,
          ctecli_metodopago: c.ctecli_metodopago,
          ctecli_regtrib: c.ctecli_regtrib,
          ctecli_pais: c.ctecli_pais,
          ctecli_factablero: c.ctecli_factablero,
          sat_uso_cfdi_k: c.sat_uso_cfdi_k,
          ctecli_complemento: c.ctecli_complemento,
          ctecli_aplicacanje: c.ctecli_aplicacanje,
          ctecli_aplicadev: c.ctecli_aplicadev,
          ctecli_desglosakit: c.ctecli_desglosakit,
          faccom_codigo_k: c.faccom_codigo_k,
          ctecli_facgrupo: c.ctecli_facgrupo,
          facads_codigo_k: c.facads_codigo_k,
          s_maqedo: c.s_maqedo,
          s_fecha: c.s_fecha,
          s_fi: c.s_fi,
          s_guid: c.s_guid,
          s_guidlog: c.s_guidlog,
          s_usuario: c.s_usuario,
          s_usuariodb: c.s_usuariodb,
          s_guidnot: c.s_guidnot
        }
      )

    query
    |> Repo.all()
    |> Enum.map(&fix_concat_types/1)
  end

  # Convierte valores enteros a strings en campos concatenados que SQL Server puede retornar como enteros
  defp fix_concat_types(cliente) do
    %{
      cliente
      | frecuencia: safe_to_string(cliente.frecuencia),
        canal: safe_to_string(cliente.canal),
        subcanal: safe_to_string(cliente.subcanal),
        cadena: safe_to_string(cliente.cadena),
        paquete_serv: safe_to_string(cliente.paquete_serv),
        regimen: safe_to_string(cliente.regimen),
        estado: safe_to_string(cliente.estado),
        municipio: safe_to_string(cliente.municipio),
        localidad: safe_to_string(cliente.localidad),
        map_x: safe_to_string(cliente.map_x),
        map_y: safe_to_string(cliente.map_y)
    }
  end

  defp safe_to_string(nil), do: nil
  defp safe_to_string(value) when is_binary(value), do: value
  defp safe_to_string(value) when is_integer(value), do: Integer.to_string(value)
  defp safe_to_string(value) when is_float(value), do: Float.to_string(value)
  defp safe_to_string(%Decimal{} = value), do: Decimal.to_string(value)
  defp safe_to_string(value), do: to_string(value)

  @doc """
  Lista clientes resumidos (solo info básica para tabla)
  """
  def list_clientes_resumen(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin) do
    query =
      from(c in Cliente,
        left_join: d in Direccion,
        on: c.ctecli_codigo_k == d.ctecli_codigo_k,
        left_join: ruta in Ruta,
        on: ruta.vtarut_codigo_k in [d.vtarut_codigo_k_pre, d.vtarut_codigo_k_aut],
        left_join: edo in Estado,
        on: d.mapedo_codigo_k == edo.mapedo_codigo_k,
        where: c.s_maqedo == 10,
        where:
          (d.vtarut_codigo_k_pre >= ^vtarut_codigo_k_ini and
             d.vtarut_codigo_k_pre <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_ent >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_ent <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_aut >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_aut <= ^vtarut_codigo_k_fin),
        where: ruta.sysudn_codigo_k == ^sysudn_codigo_k,
        distinct: true,
        order_by: [asc: c.ctecli_codigo_k],
        select: %{
          codigo: c.ctecli_codigo_k,
          razon_social: c.ctecli_razonsocial,
          nombre_comercial: c.ctecli_dencomercia,
          rfc: c.ctecli_rfc,
          telefono: d.ctedir_telefono,
          estado: edo.mapedo_descripcion,
          colonia: d.ctedir_colonia,
          calle: d.ctedir_calle,
          preventa: d.vtarut_codigo_k_pre,
          entrega: d.vtarut_codigo_k_ent,
          autoventa: d.vtarut_codigo_k_aut
        }
      )

    query
    |> Repo.all()
    |> Enum.map(&fix_map_encoding/1)
  end

  @doc """
  Lista clientes con paginación usando Flop

  ## Filtros soportados:
  - sysudn: Código de UDN
  - ruta: Código de ruta (preventa/entrega/autoventa)
  - estatus: Estado del cliente (A/I)
  - search: Búsqueda por código, razón social o RFC
  """
  def list_clientes_with_flop(params \\ %{}) do
    # Valores por defecto - manejar tanto nil como string vacío
    sysudn_codigo_k = get_param_or_default(params["sysudn"], "100")
    vtarut_codigo_k_ini = get_param_or_default(params["ruta_desde"], "001")
    vtarut_codigo_k_fin = get_param_or_default(params["ruta_hasta"], "99999")

    base_query =
      from(c in Cliente,
        left_join: d in Direccion,
        on: c.ctecli_codigo_k == d.ctecli_codigo_k,
        left_join: ruta in Ruta,
        on: ruta.vtarut_codigo_k in [d.vtarut_codigo_k_pre, d.vtarut_codigo_k_aut],
        left_join: edo in Estado,
        on: d.mapedo_codigo_k == edo.mapedo_codigo_k,
        where: c.s_maqedo == 10,
        where:
          (d.vtarut_codigo_k_pre >= ^vtarut_codigo_k_ini and
             d.vtarut_codigo_k_pre <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_ent >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_ent <= ^vtarut_codigo_k_fin) or
            (d.vtarut_codigo_k_aut >= ^vtarut_codigo_k_ini and
               d.vtarut_codigo_k_aut <= ^vtarut_codigo_k_fin),
        where: ruta.sysudn_codigo_k == ^sysudn_codigo_k,
        distinct: true,
        order_by: [asc: c.ctecli_codigo_k],
        select: %{
          # Campos principales para mostrar en tabla
          udn: ruta.sysudn_codigo_k,
          preventa: d.vtarut_codigo_k_pre,
          entrega: d.vtarut_codigo_k_ent,
          autoventa: d.vtarut_codigo_k_aut,
          ctedir_codigo_k: d.ctedir_codigo_k,
          rfc: c.ctecli_rfc,
          codigo: c.ctecli_codigo_k,
          razon_social: c.ctecli_razonsocial,
          diascredito: c.ctecli_diascredito,
          limite_credito: c.ctecli_limitecredi,
          paquete_codigo: c.ctepaq_codigo_k,
          frecuencia_codigo: d.ctepfr_codigo_k,
          email_receptor: c.ctecli_fereceptormail,
          forma_pago: c.ctecli_formapago,
          metodo_pago: c.ctecli_metodopago,
          estatus: fragment(
            "CASE WHEN ? = 10 THEN 'A' WHEN ? = 30 THEN 'P' ELSE 'B' END",
            c.s_maqedo, c.s_maqedo
          ),

          # Campos adicionales (visibles al seleccionar)
          nombre_comercial: c.ctecli_dencomercia,
          telefono: d.ctedir_telefono,
          estado: edo.mapedo_descripcion,
          colonia: d.ctedir_colonia,
          calle: d.ctedir_calle,
          map_x: fragment("CAST(? AS VARCHAR(50))", d.map_x),
          map_y: fragment("CAST(? AS VARCHAR(50))", d.map_y)
        }
      )

    # Aplicar filtro de búsqueda si existe
    # NOTA: No podemos filtrar por aliases del select, necesitamos usar los campos originales
    filtered_query =
      case params["search"] do
        nil ->
          base_query

        "" ->
          base_query

        search ->
          search_term = "%#{String.trim(search)}%"

          from(c in Cliente,
            left_join: d in Direccion,
            on: c.ctecli_codigo_k == d.ctecli_codigo_k,
            left_join: ruta in Ruta,
            on: ruta.vtarut_codigo_k in [d.vtarut_codigo_k_pre, d.vtarut_codigo_k_aut],
            left_join: edo in Estado,
            on: d.mapedo_codigo_k == edo.mapedo_codigo_k,
            where: c.s_maqedo == 10,
            where:
              (d.vtarut_codigo_k_pre >= ^vtarut_codigo_k_ini and
                 d.vtarut_codigo_k_pre <= ^vtarut_codigo_k_fin) or
                (d.vtarut_codigo_k_ent >= ^vtarut_codigo_k_ini and
                   d.vtarut_codigo_k_ent <= ^vtarut_codigo_k_fin) or
                (d.vtarut_codigo_k_aut >= ^vtarut_codigo_k_ini and
                   d.vtarut_codigo_k_aut <= ^vtarut_codigo_k_fin),
            where: ruta.sysudn_codigo_k == ^sysudn_codigo_k,
            where:
              ilike(c.ctecli_codigo_k, ^search_term) or
                ilike(c.ctecli_razonsocial, ^search_term) or
                ilike(c.ctecli_rfc, ^search_term) or
                ilike(c.ctecli_dencomercia, ^search_term) or
                ilike(d.ctedir_colonia, ^search_term),
            distinct: true,
            order_by: [asc: c.ctecli_codigo_k],
            select: %{
              udn: ruta.sysudn_codigo_k,
              preventa: d.vtarut_codigo_k_pre,
              entrega: d.vtarut_codigo_k_ent,
              autoventa: d.vtarut_codigo_k_aut,
              ctedir_codigo_k: d.ctedir_codigo_k,
              rfc: c.ctecli_rfc,
              codigo: c.ctecli_codigo_k,
              razon_social: c.ctecli_razonsocial,
              diascredito: c.ctecli_diascredito,
              limite_credito: c.ctecli_limitecredi,
              paquete_codigo: c.ctepaq_codigo_k,
              frecuencia_codigo: d.ctepfr_codigo_k,
              email_receptor: c.ctecli_fereceptormail,
              forma_pago: c.ctecli_formapago,
              metodo_pago: c.ctecli_metodopago,
              estatus:
                fragment(
                  "CASE WHEN ? = 10 THEN 'A' WHEN ? = 30 THEN 'P' ELSE 'B' END",
                  c.s_maqedo,
                  c.s_maqedo
                ),
              nombre_comercial: c.ctecli_dencomercia,
              telefono: d.ctedir_telefono,
              estado: edo.mapedo_descripcion,
              colonia: d.ctedir_colonia,
              calle: d.ctedir_calle,
              map_x: fragment("CAST(? AS VARCHAR(50))", d.map_x),
              map_y: fragment("CAST(? AS VARCHAR(50))", d.map_y)
            }
          )
      end

    # Configurar Flop con 20 registros por página
    flop_params = Map.merge(%{"page_size" => "20"}, params)

    case Flop.validate_and_run(filtered_query, flop_params, for: Cliente) do
      {:ok, {clientes, meta}} ->
        clientes_fixed = clientes
        |> Enum.map(&fix_map_encoding/1)
        |> Enum.map(&fix_types/1)
        {:ok, {clientes_fixed, meta}}

      {:error, meta} ->
        {:error, meta}
    end
  end

  # Helper para obtener parámetro o usar valor por defecto
  # Maneja tanto nil como string vacío
  defp get_param_or_default(nil, default), do: default
  defp get_param_or_default("", default), do: default
  defp get_param_or_default(value, _default) when is_binary(value), do: value

  @doc """
  Obtiene un cliente por su código con todas sus direcciones.

  ## Parámetros
    * `codigo` - Código del cliente

  ## Ejemplos
      iex> get_cliente_by_codigo("0002")
      {:ok, %{cliente: %{...}, direcciones: [...]}}
  """
  def get_cliente_by_codigo(codigo) do
    # Buscar cliente - seleccionar solo campos reales (no virtuales)
    cliente_query =
      from(c in Cliente,
        where: c.ctecli_codigo_k == ^codigo,
        select: %{
          ctecli_codigo_k: c.ctecli_codigo_k,
          ctecli_razonsocial: c.ctecli_razonsocial,
          ctecli_dencomercia: c.ctecli_dencomercia,
          ctecli_rfc: c.ctecli_rfc,
          ctecli_fechaalta: c.ctecli_fechaalta,
          ctecli_fechabaja: c.ctecli_fechabaja,
          ctecli_causabaja: c.ctecli_causabaja,
          ctecli_edocred: c.ctecli_edocred,
          ctecli_diascredito: c.ctecli_diascredito,
          ctecli_limitecredi: c.ctecli_limitecredi,
          ctecli_tipodefact: c.ctecli_tipodefact,
          ctecli_tipofacdes: c.ctecli_tipofacdes,
          ctecli_tipopago: c.ctecli_tipopago,
          ctecli_creditoobs: c.ctecli_creditoobs,
          ctetpo_codigo_k: c.ctetpo_codigo_k,
          ctesca_codigo_k: c.ctesca_codigo_k,
          ctepaq_codigo_k: c.ctepaq_codigo_k,
          ctereg_codigo_k: c.ctereg_codigo_k,
          ctecad_codigo_k: c.ctecad_codigo_k,
          ctecan_codigo_k: c.ctecan_codigo_k,
          ctecli_generico: c.ctecli_generico,
          cfgmon_codigo_k: c.cfgmon_codigo_k,
          ctecli_observaciones: c.ctecli_observaciones,
          systra_codigo_k: c.systra_codigo_k,
          facadd_codigo_k: c.facadd_codigo_k,
          ctecli_fereceptor: c.ctecli_fereceptor,
          ctecli_fereceptormail: c.ctecli_fereceptormail,
          ctepor_codigo_k: c.ctepor_codigo_k,
          ctecli_tipodefacr: c.ctecli_tipodefacr,
          condim_codigo_k: c.condim_codigo_k,
          ctecli_cxcliq: c.ctecli_cxcliq,
          ctecli_nocta: c.ctecli_nocta,
          ctecli_dscantimp: c.ctecli_dscantimp,
          ctecli_desglosaieps: c.ctecli_desglosaieps,
          ctecli_periodorefac: c.ctecli_periodorefac,
          ctecli_contacto: c.ctecli_contacto,
          cfgban_codigo_k: c.cfgban_codigo_k,
          ctecli_cargaespecifica: c.ctecli_cargaespecifica,
          ctecli_caducidadmin: c.ctecli_caducidadmin,
          ctecli_ctlsanitario: c.ctecli_ctlsanitario,
          ctecli_formapago: c.ctecli_formapago,
          ctecli_metodopago: c.ctecli_metodopago,
          ctecli_regtrib: c.ctecli_regtrib,
          ctecli_pais: c.ctecli_pais,
          ctecli_factablero: c.ctecli_factablero,
          sat_uso_cfdi_k: c.sat_uso_cfdi_k,
          ctecli_complemento: c.ctecli_complemento,
          ctecli_aplicacanje: c.ctecli_aplicacanje,
          ctecli_aplicadev: c.ctecli_aplicadev,
          ctecli_desglosakit: c.ctecli_desglosakit,
          faccom_codigo_k: c.faccom_codigo_k,
          ctecli_facgrupo: c.ctecli_facgrupo,
          facads_codigo_k: c.facads_codigo_k,
          s_maqedo: c.s_maqedo,
          s_fecha: c.s_fecha,
          s_fi: c.s_fi,
          s_guid: c.s_guid,
          s_guidlog: c.s_guidlog,
          s_usuario: c.s_usuario,
          s_usuariodb: c.s_usuariodb,
          s_guidnot: c.s_guidnot
        }
      )

    case Repo.one(cliente_query) do
      nil ->
        {:error, :not_found}

      cliente ->
        # Buscar direcciones del cliente
        direcciones_query =
          from(d in Direccion,
            where: d.ctecli_codigo_k == ^codigo,
            select: d
          )

        direcciones = Repo.all(direcciones_query)

        {:ok, %{cliente: cliente, direcciones: direcciones}}
    end
  end
end
