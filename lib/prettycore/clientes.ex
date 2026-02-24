defmodule Prettycore.Clientes do
  @moduledoc """
  Contexto para gestión de clientes usando API REST EN_RESTHELPER.

  Este módulo consume datos desde la API REST en lugar de
  consultas directas a SQL Server.

  Base URL: https://s2.ecore.ninja:1522/SP/EN_RESTHELPER/
  """

  alias Prettycore.Api.Client, as: Api

  @doc """
  Obtiene estadísticas de un cliente/dirección desde la API Estadisticas.

  Retorna un mapa con :pedido, :venta_anual, :cartera, :enfriadores
  """
  def get_estadisticas(cliente_codigo, dir_codigo, token \\ nil) do
    case Api.get_estadisticas(cliente_codigo, dir_codigo, token) do
      {:ok, [data | _]} when is_map(data) ->
        pedidos = Map.get(data, "pedido", [])
        venta_anual = Map.get(data, "VentaAnual", [])
        cartera = Map.get(data, "Cartera", [])
        enfriadores = Map.get(data, "Enfriadores", [])

        ultimo_pedido = List.first(pedidos)

        total_venta_anual =
          venta_anual
          |> Enum.map(fn v -> parse_decimal(v["Venta"]) end)
          |> Enum.sum()

        cartera_data = List.first(cartera) || %{}
        vigente = parse_decimal(cartera_data["VIGENTE"])
        vencido = parse_decimal(cartera_data["VENCIDO"])

        enfriadores_count =
          case List.first(enfriadores) do
            %{"Enfriadores" => n} -> n
            _ -> 0
          end

        clasificacion_data = Map.get(data, "Clasificacion", [])
        clasificacion =
          case List.first(clasificacion_data) do
            %{"Clasificacion" => c} when is_binary(c) -> parse_clasificacion(c)
            _ -> nil
          end

        {:ok, %{
          pedido: ultimo_pedido,
          venta_anual: venta_anual,
          total_venta_anual: total_venta_anual,
          cartera_vigente: vigente,
          cartera_vencida: vencido,
          enfriadores: enfriadores_count,
          clasificacion: clasificacion
        }}

      {:ok, _} ->
        {:ok, %{
          pedido: nil,
          venta_anual: [],
          total_venta_anual: 0.0,
          cartera_vigente: 0.0,
          cartera_vencida: 0.0,
          enfriadores: 0,
          clasificacion: nil
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_decimal(nil), do: 0.0
  defp parse_decimal(v) when is_float(v), do: v
  defp parse_decimal(v) when is_integer(v), do: v * 1.0
  defp parse_decimal(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> 0.0
    end
  end
  defp parse_decimal(%Decimal{} = d), do: Decimal.to_float(d)
  defp parse_decimal(_), do: 0.0

  @doc "Invalida el caché de clientes y direcciones para forzar recarga desde API"
  def invalidar_cache do
    :persistent_term.erase(:cache_cte_clientes)
  end

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
  def list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin, token \\ nil) do
    case Api.get_all("CTE_CLIENTES", token) do
      {:ok, registros} ->
        registros
        |> Enum.filter(fn r -> r["S_MAQEDO"] == 10 || r["S_MAQEDO"] == "10" end)
        |> Enum.group_by(& &1["CTECLI_CODIGO_K"])
        |> Enum.flat_map(fn {_codigo, registros_cliente} ->
          filtrados = Enum.filter(registros_cliente, fn r ->
            ruta_pre = r["VTARUT_CODIGO_K_PRE"] || ""
            ruta_ent = r["VTARUT_CODIGO_K_ENT"] || ""
            ruta_aut = r["VTARUT_CODIGO_K_AUT"] || ""

            (ruta_pre >= vtarut_codigo_k_ini and ruta_pre <= vtarut_codigo_k_fin) or
            (ruta_ent >= vtarut_codigo_k_ini and ruta_ent <= vtarut_codigo_k_fin) or
            (ruta_aut >= vtarut_codigo_k_ini and ruta_aut <= vtarut_codigo_k_fin)
          end)

          if Enum.any?(filtrados) do
            r = List.first(filtrados)
            [build_cliente_completo(r, r, sysudn_codigo_k)]
          else
            []
          end
        end)
        |> Enum.map(&fix_map_encoding/1)

      _ ->
        []
    end
  end

  # Helper para obtener direcciones de un cliente individual (usado en list_clientes_resumen)
  defp get_direcciones_cliente(cliente_codigo, token \\ nil) do
    case Api.get_direcciones_cliente(cliente_codigo, token) do
      {:ok, direcciones} -> direcciones
      {:error, _} -> []
    end
  end

  defp build_cliente_completo(cliente, dir, sysudn_codigo_k) do
    %{
      # Estatus calculado
      estatus: case cliente["S_MAQEDO"] do
        10 -> "---ACTIVO---"
        30 -> "---PROSPECTO---"
        _ -> "---BAJA---"
      end,

      # Datos de ruta
      udn: sysudn_codigo_k,
      preventa: dir["VTARUT_CODIGO_K_PRE"],
      entrega: dir["VTARUT_CODIGO_K_ENT"],
      autoventa: dir["VTARUT_CODIGO_K_AUT"],

      # Identificadores dirección
      ctepfr_codigo_k: dir["CTEPFR_CODIGO_K"],
      ctedir_codigo_k: dir["CTEDIR_CODIGO_K"],

      # RFC
      rfc: cliente["CTECLI_RFC"],

      # Coordenadas
      map_x: safe_to_string(dir["MAP_X"]),
      map_y: safe_to_string(dir["MAP_Y"]),

      # Dirección física
      ctedir_calle: dir["CTEDIR_CALLE"],
      ctedir_colonia: dir["CTEDIR_COLONIA"],
      ctedir_callenumext: dir["CTEDIR_CALLENUMEXT"],
      ctedir_callenumint: dir["CTEDIR_CALLENUMINT"],
      ctedir_telefono: dir["CTEDIR_TELEFONO"],
      ctedir_responsable: dir["CTEDIR_RESPONSABLE"],
      ctedir_calleentre1: dir["CTEDIR_CALLEENTRE1"],
      ctedir_calleentre2: dir["CTEDIR_CALLEENTRE2"],
      ctedir_cp: dir["CTEDIR_CP"],

      # Todos los campos del cliente
      ctecli_codigo_k: cliente["CTECLI_CODIGO_K"],
      ctecli_razonsocial: cliente["CTECLI_RAZONSOCIAL"],
      ctecli_dencomercia: cliente["CTECLI_DENCOMERCIA"],
      ctecli_fechaalta: cliente["CTECLI_FECHAALTA"],
      ctecli_fechabaja: cliente["CTECLI_FECHABAJA"],
      ctecli_causabaja: cliente["CTECLI_CAUSABAJA"],
      ctecli_edocred: cliente["CTECLI_EDOCRED"],
      ctecli_diascredito: cliente["CTECLI_DIASCREDITO"],
      ctecli_limitecredi: cliente["CTECLI_LIMITECREDI"],
      ctecli_tipodefact: cliente["CTECLI_TIPODEFACT"],
      ctecli_tipofacdes: cliente["CTECLI_TIPOFACDES"],
      ctecli_tipopago: cliente["CTECLI_TIPOPAGO"],
      ctecli_creditoobs: cliente["CTECLI_CREDITOOBS"],
      ctetpo_codigo_k: cliente["CTETPO_CODIGO_K"],
      ctesca_codigo_k: cliente["CTESCA_CODIGO_K"],
      ctepaq_codigo_k: cliente["CTEPAQ_CODIGO_K"],
      ctereg_codigo_k: cliente["CTEREG_CODIGO_K"],
      ctecad_codigo_k: cliente["CTECAD_CODIGO_K"],
      ctecan_codigo_k: cliente["CTECAN_CODIGO_K"],
      ctecli_generico: cliente["CTECLI_GENERICO"],
      cfgmon_codigo_k: cliente["CFGMON_CODIGO_K"],
      ctecli_observaciones: cliente["CTECLI_OBSERVACIONES"],
      systra_codigo_k: cliente["SYSTRA_CODIGO_K"],
      facadd_codigo_k: cliente["FACADD_CODIGO_K"],
      ctecli_fereceptor: cliente["CTECLI_FERECEPTOR"],
      ctecli_fereceptormail: cliente["CTECLI_FERECEPTORMAIL"],
      ctepor_codigo_k: cliente["CTEPOR_CODIGO_K"],
      ctecli_tipodefacr: cliente["CTECLI_TIPODEFACR"],
      condim_codigo_k: cliente["CONDIM_CODIGO_K"],
      ctecli_cxcliq: cliente["CTECLI_CXCLIQ"],
      ctecli_nocta: cliente["CTECLI_NOCTA"],
      ctecli_dscantimp: cliente["CTECLI_DSCANTIMP"],
      ctecli_desglosaieps: cliente["CTECLI_DESGLOSAIEPS"],
      ctecli_periodorefac: cliente["CTECLI_PERIODOREFAC"],
      ctecli_contacto: cliente["CTECLI_CONTACTO"],
      cfgban_codigo_k: cliente["CFGBAN_CODIGO_K"],
      ctecli_cargaespecifica: cliente["CTECLI_CARGAESPECIFICA"],
      ctecli_caducidadmin: cliente["CTECLI_CADUCIDADMIN"],
      ctecli_ctlsanitario: cliente["CTECLI_CTLSANITARIO"],
      ctecli_formapago: cliente["CTECLI_FORMAPAGO"],
      ctecli_metodopago: cliente["CTECLI_METODOPAGO"],
      ctecli_regtrib: cliente["CTECLI_REGTRIB"],
      ctecli_pais: cliente["CTECLI_PAIS"],
      ctecli_factablero: cliente["CTECLI_FACTABLERO"],
      sat_uso_cfdi_k: cliente["SAT_USO_CFDI_K"],
      ctecli_complemento: cliente["CTECLI_COMPLEMENTO"],
      ctecli_aplicacanje: cliente["CTECLI_APLICACANJE"],
      ctecli_aplicadev: cliente["CTECLI_APLICADEV"],
      ctecli_desglosakit: cliente["CTECLI_DESGLOSAKIT"],
      faccom_codigo_k: cliente["FACCOM_CODIGO_K"],
      ctecli_facgrupo: cliente["CTECLI_FACGRUPO"],
      facads_codigo_k: cliente["FACADS_CODIGO_K"],
      s_maqedo: cliente["S_MAQEDO"],
      s_fecha: cliente["S_FECHA"],
      s_fi: cliente["S_FI"],
      s_guid: cliente["S_GUID"],
      s_guidlog: cliente["S_GUIDLOG"],
      s_usuario: cliente["S_USUARIO"],
      s_usuariodb: cliente["S_USUARIODB"],
      s_guidnot: cliente["S_GUIDNOT"]
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
    case Api.get_all("CTE_CLIENTES") do
      {:ok, registros} ->
        registros
        |> Enum.filter(fn r -> r["S_MAQEDO"] == 10 || r["S_MAQEDO"] == "10" end)
        |> Enum.group_by(& &1["CTECLI_CODIGO_K"])
        |> Enum.flat_map(fn {_codigo, registros_cliente} ->
          filtrados = Enum.filter(registros_cliente, fn r ->
            ruta_pre = r["VTARUT_CODIGO_K_PRE"] || ""
            ruta_ent = r["VTARUT_CODIGO_K_ENT"] || ""
            ruta_aut = r["VTARUT_CODIGO_K_AUT"] || ""

            (ruta_pre >= vtarut_codigo_k_ini and ruta_pre <= vtarut_codigo_k_fin) or
            (ruta_ent >= vtarut_codigo_k_ini and ruta_ent <= vtarut_codigo_k_fin) or
            (ruta_aut >= vtarut_codigo_k_ini and ruta_aut <= vtarut_codigo_k_fin)
          end)

          if Enum.any?(filtrados) do
            r = List.first(filtrados)
            [%{
              codigo: r["CTECLI_CODIGO_K"],
              razon_social: r["CTECLI_RAZONSOCIAL"],
              nombre_comercial: r["CTECLI_DENCOMERCIA"],
              rfc: r["CTECLI_RFC"],
              telefono: r["CTEDIR_TELEFONO"],
              estado: get_estado_nombre(r["MAPEDO_CODIGO_K"]),
              colonia: r["CTEDIR_COLONIA"],
              calle: r["CTEDIR_CALLE"],
              preventa: r["VTARUT_CODIGO_K_PRE"],
              entrega: r["VTARUT_CODIGO_K_ENT"],
              autoventa: r["VTARUT_CODIGO_K_AUT"]
            }]
          else
            []
          end
        end)
        |> Enum.map(&fix_map_encoding/1)

      {:error, _} ->
        []
    end
  end

  defp get_estado_nombre(estado_codigo, _token \\ nil)
  defp get_estado_nombre(nil, _token), do: nil
  defp get_estado_nombre(estado_codigo, _token) do
    case Prettycore.PsqlRepo.get(Prettycore.Map.Estado, estado_codigo) do
      nil -> nil
      estado -> estado.descripcion
    end
  end

  @doc """
  Lista clientes con paginación usando Flop

  ## Filtros soportados:
  - sysudn: Código de UDN
  - ruta: Código de ruta (preventa/entrega/autoventa)
  - estatus: Estado del cliente (A/I)
  - search: Búsqueda por código, razón social o RFC
  """
  def list_clientes_with_flop(params \\ %{}, token \\ nil) do
    sysudn_codigo_k = get_param_or_default(params["sysudn"], "100")
    vtarut_codigo_k_ini = get_param_or_default(params["ruta_desde"], "001")
    vtarut_codigo_k_fin = get_param_or_default(params["ruta_hasta"], "99999")
    search_term = params["search"]
    clasificacion_filter = params["clasificacion"]
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "20")

    # Obtener estados desde PostgreSQL local
    todos_estados = Prettycore.PsqlRepo.all(Prettycore.Map.Estado)

    # Obtener clientes con caché (se invalida al guardar)
    registros_data =
      case :persistent_term.get(:cache_cte_clientes, nil) do
        nil ->
          case Api.get_all("CTE_CLIENTES", token) do
            {:ok, data} -> :persistent_term.put(:cache_cte_clientes, data); data
            {:error, reason} -> {:error, reason}
          end
        cached -> cached
      end

    with registros when is_list(registros) <- registros_data do

      # Indexar estados por código para búsqueda rápida
      estados_por_codigo = Map.new(todos_estados, fn e ->
        {e.codigo_k, e.descripcion}
      end)

      # Filtrar clientes activos, agrupar por código y procesar
      clientes_procesados = registros
      |> Enum.filter(fn r -> r["S_MAQEDO"] == 10 || r["S_MAQEDO"] == "10" end)
      |> Enum.group_by(& &1["CTECLI_CODIGO_K"])
      |> Enum.flat_map(fn {_codigo, registros_cliente} ->
        filtrados = Enum.filter(registros_cliente, fn r ->
          ruta_pre = r["VTARUT_CODIGO_K_PRE"] || ""
          ruta_ent = r["VTARUT_CODIGO_K_ENT"] || ""
          ruta_aut = r["VTARUT_CODIGO_K_AUT"] || ""

          (ruta_pre >= vtarut_codigo_k_ini and ruta_pre <= vtarut_codigo_k_fin) or
          (ruta_ent >= vtarut_codigo_k_ini and ruta_ent <= vtarut_codigo_k_fin) or
          (ruta_aut >= vtarut_codigo_k_ini and ruta_aut <= vtarut_codigo_k_fin)
        end)

        if Enum.any?(filtrados) do
          r = List.first(filtrados)
          [build_cliente_flop(r, r, sysudn_codigo_k, estados_por_codigo)]
        else
          []
        end
      end)

      # Aplicar búsqueda si existe
      clientes_filtrados = if search_term && search_term != "" do
        search_lower = String.downcase(search_term)
        Enum.filter(clientes_procesados, fn c ->
          String.contains?(String.downcase(c.codigo || ""), search_lower) or
          String.contains?(String.downcase(c.razon_social || ""), search_lower) or
          String.contains?(String.downcase(c.rfc || ""), search_lower) or
          String.contains?(String.downcase(c.nombre_comercial || ""), search_lower) or
          String.contains?(String.downcase(c.colonia || ""), search_lower)
        end)
      else
        clientes_procesados
      end

      # Aplicar filtro de clasificación
      clientes_filtrados = if clasificacion_filter && clasificacion_filter != "" do
        filter_upper = String.upcase(clasificacion_filter)
        Enum.filter(clientes_filtrados, fn c ->
          clasif = c.clasificacion
          cond do
            is_nil(clasif) or clasif == "" -> filter_upper == "SIN RANGO"
            true -> String.upcase(String.trim(clasif)) == filter_upper
          end
        end)
      else
        clientes_filtrados
      end

      # Aplicar paginación manual
      total_count = length(clientes_filtrados)
      total_pages = ceil(total_count / page_size)
      offset = (page - 1) * page_size

      clientes_paginados = clientes_filtrados
      |> Enum.drop(offset)
      |> Enum.take(page_size)
      |> Enum.map(&fix_map_encoding/1)
      |> Enum.map(&fix_types/1)

      # Crear meta de paginación compatible con Flop
      meta = %Flop.Meta{
        current_page: page,
        page_size: page_size,
        total_count: total_count,
        total_pages: total_pages,
        has_previous_page?: page > 1,
        has_next_page?: page < total_pages,
        flop: %Flop{page: page, page_size: page_size}
      }

      {:ok, {clientes_paginados, meta}}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_cliente_flop(cliente, dir, sysudn_codigo_k, estados_por_codigo) do
    %{
      udn: sysudn_codigo_k,
      preventa: dir["VTARUT_CODIGO_K_PRE"],
      entrega: dir["VTARUT_CODIGO_K_ENT"],
      autoventa: dir["VTARUT_CODIGO_K_AUT"],
      ctedir_codigo_k: dir["CTEDIR_CODIGO_K"],
      rfc: cliente["CTECLI_RFC"],
      codigo: cliente["CTECLI_CODIGO_K"],
      razon_social: cliente["CTECLI_RAZONSOCIAL"],
      diascredito: cliente["CTECLI_DIASCREDITO"],
      limite_credito: cliente["CTECLI_LIMITECREDI"],
      paquete_codigo: cliente["CTEPAQ_CODIGO_K"],
      frecuencia_codigo: dir["CTEPFR_CODIGO_K"],
      email_receptor: cliente["CTECLI_FERECEPTORMAIL"],
      forma_pago: cliente["CTECLI_FORMAPAGO"],
      metodo_pago: cliente["CTECLI_METODOPAGO"],
      estatus: case cliente["S_MAQEDO"] do
        10 -> "A"
        30 -> "P"
        _ -> "B"
      end,
      nombre_comercial: cliente["CTECLI_DENCOMERCIA"],
      telefono: dir["CTEDIR_TELEFONO"],
      estado: Map.get(estados_por_codigo, dir["MAPEDO_CODIGO_K"]),
      colonia: dir["CTEDIR_COLONIA"],
      calle: dir["CTEDIR_CALLE"],
      map_x: safe_to_string(dir["MAP_X"]),
      map_y: safe_to_string(dir["MAP_Y"]),
      clasificacion: parse_clasificacion(dir["Clasificacion"])
    }
  end

  # Helper para obtener parámetro o usar valor por defecto
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
  def get_cliente_by_codigo(codigo, token \\ nil) do
    case Prettycore.ClientesApi.info_cliente(codigo, token) do
      {:ok, %{cliente: cliente_raw, direcciones: dirs_raw}} ->
        cliente_normalizado = normalize_cliente(cliente_raw)
        dirs = Enum.map(dirs_raw, &normalize_direccion/1)
        {:ok, %{cliente: cliente_normalizado, direcciones: dirs}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Normaliza campos del cliente de API (claves string) a átomos
  defp normalize_cliente(cliente) do
    %{
      ctecli_codigo_k: cliente["CTECLI_CODIGO_K"],
      ctecli_razonsocial: cliente["CTECLI_RAZONSOCIAL"],
      ctecli_dencomercia: cliente["CTECLI_DENCOMERCIA"],
      ctecli_rfc: cliente["CTECLI_RFC"],
      ctecli_fechaalta: cliente["CTECLI_FECHAALTA"],
      ctecli_fechabaja: cliente["CTECLI_FECHABAJA"],
      ctecli_causabaja: cliente["CTECLI_CAUSABAJA"],
      ctecli_edocred: cliente["CTECLI_EDOCRED"],
      ctecli_diascredito: cliente["CTECLI_DIASCREDITO"],
      ctecli_limitecredi: cliente["CTECLI_LIMITECREDI"],
      ctecli_tipodefact: cliente["CTECLI_TIPODEFACT"],
      ctecli_tipofacdes: cliente["CTECLI_TIPOFACDES"],
      ctecli_tipopago: cliente["CTECLI_TIPOPAGO"],
      ctecli_creditoobs: cliente["CTECLI_CREDITOOBS"],
      ctetpo_codigo_k: cliente["CTETPO_CODIGO_K"],
      ctesca_codigo_k: cliente["CTESCA_CODIGO_K"],
      ctepaq_codigo_k: cliente["CTEPAQ_CODIGO_K"],
      ctereg_codigo_k: cliente["CTEREG_CODIGO_K"],
      ctecad_codigo_k: cliente["CTECAD_CODIGO_K"],
      ctecan_codigo_k: cliente["CTECAN_CODIGO_K"],
      ctecli_generico: cliente["CTECLI_GENERICO"],
      cfgmon_codigo_k: cliente["CFGMON_CODIGO_K"],
      ctecli_observaciones: cliente["CTECLI_OBSERVACIONES"],
      systra_codigo_k: cliente["SYSTRA_CODIGO_K"],
      facadd_codigo_k: cliente["FACADD_CODIGO_K"],
      ctecli_fereceptor: cliente["CTECLI_FERECEPTOR"],
      ctecli_fereceptormail: cliente["CTECLI_FERECEPTORMAIL"],
      ctepor_codigo_k: cliente["CTEPOR_CODIGO_K"],
      ctecli_tipodefacr: cliente["CTECLI_TIPODEFACR"],
      condim_codigo_k: cliente["CONDIM_CODIGO_K"],
      ctecli_cxcliq: cliente["CTECLI_CXCLIQ"],
      ctecli_nocta: cliente["CTECLI_NOCTA"],
      ctecli_dscantimp: cliente["CTECLI_DSCANTIMP"],
      ctecli_desglosaieps: cliente["CTECLI_DESGLOSAIEPS"],
      ctecli_periodorefac: cliente["CTECLI_PERIODOREFAC"],
      ctecli_contacto: cliente["CTECLI_CONTACTO"],
      cfgban_codigo_k: cliente["CFGBAN_CODIGO_K"],
      ctecli_cargaespecifica: cliente["CTECLI_CARGAESPECIFICA"],
      ctecli_caducidadmin: cliente["CTECLI_CADUCIDADMIN"],
      ctecli_ctlsanitario: cliente["CTECLI_CTLSANITARIO"],
      ctecli_formapago: cliente["CTECLI_FORMAPAGO"],
      ctecli_metodopago: cliente["CTECLI_METODOPAGO"],
      ctecli_regtrib: cliente["CTECLI_REGTRIB"],
      ctecli_pais: cliente["CTECLI_PAIS"],
      ctecli_factablero: cliente["CTECLI_FACTABLERO"],
      sat_uso_cfdi_k: cliente["SAT_USO_CFDI_K"],
      ctecli_complemento: cliente["CTECLI_COMPLEMENTO"],
      ctecli_aplicacanje: cliente["CTECLI_APLICACANJE"],
      ctecli_aplicadev: cliente["CTECLI_APLICADEV"],
      ctecli_desglosakit: cliente["CTECLI_DESGLOSAKIT"],
      faccom_codigo_k: cliente["FACCOM_CODIGO_K"],
      ctecli_facgrupo: cliente["CTECLI_FACGRUPO"],
      facads_codigo_k: cliente["FACADS_CODIGO_K"],
      s_maqedo: cliente["S_MAQEDO"],
      s_fecha: cliente["S_FECHA"],
      s_fi: cliente["S_FI"],
      s_guid: cliente["S_GUID"],
      s_guidlog: cliente["S_GUIDLOG"],
      s_usuario: cliente["S_USUARIO"],
      s_usuariodb: cliente["S_USUARIODB"],
      s_guidnot: cliente["S_GUIDNOT"],
      ctecli_timbracb: cliente["CTECLI_TIMBRACB"],
      sysemp_codigo_k: cliente["SYSEMP_CODIGO_K"],
      ctecli_novalidavencimiento: cliente["CTECLI_NOVALIDAVENCIMIENTO"],
      ctecli_compatibilidad: cliente["CTECLI_COMPATIBILIDAD"],
      satexp_codigo_k: cliente["SATEXP_CODIGO_K"],
      cfgreg_codigo_k: cliente["CFGREG_CODIGO_K"],
      ctecli_cfdi_ver: cliente["CTECLI_CFDI_VER"],
      ctecli_nombre: cliente["CTECLI_NOMBRE"],
      ctecli_aplicaregalo: cliente["CTECLI_APLICAREGALO"],
      ctecli_prvporteofac: cliente["CTECLI_PRVPORTEOFAC"],
      ctecli_noaceptafracciones: cliente["CTECLI_NOACEPTAFRACCIONES"],
      cteseg_codigo_k: cliente["CTESEG_CODIGO_K"],
      ctecli_ecommerce: cliente["CTECLI_ECOMMERCE"],
      catind_codigo_k: cliente["CATIND_CODIGO_K"],
      catpfi_codigo_k: cliente["CATPFI_CODIGO_K"]
    }
  end

  # Normaliza campos de dirección de API
  defp normalize_direccion(dir) do
    %{
      ctecli_codigo_k: dir["CTECLI_CODIGO_K"],
      ctecli_dencomercia: dir["CTECLI_DENCOMERCIA"],
      ctedir_codigo_k: dir["CTEDIR_CODIGO_K"],
      ctedir_tipofis: dir["CTEDIR_TIPOFIS"],
      ctedir_tipoent: dir["CTEDIR_TIPOENT"],
      ctedir_responsable: dir["CTEDIR_RESPONSABLE"],
      ctedir_telefono: dir["CTEDIR_TELEFONO"],
      ctedir_calle: dir["CTEDIR_CALLE"],
      ctedir_callenumext: dir["CTEDIR_CALLENUMEXT"],
      ctedir_callenumint: dir["CTEDIR_CALLENUMINT"],
      ctedir_colonia: dir["CTEDIR_COLONIA"],
      ctedir_calleentre1: dir["CTEDIR_CALLEENTRE1"],
      ctedir_calleentre2: dir["CTEDIR_CALLEENTRE2"],
      ctedir_cp: dir["CTEDIR_CP"],
      mapedo_codigo_k: dir["MAPEDO_CODIGO_K"],
      mapmun_codigo_k: dir["MAPMUN_CODIGO_K"],
      maploc_codigo_k: dir["MAPLOC_CODIGO_K"],
      map_x: dir["MAP_X"],
      map_y: dir["MAP_Y"],
      vtarut_codigo_k_pre: dir["VTARUT_CODIGO_K_PRE"],
      vtarut_codigo_k_ent: dir["VTARUT_CODIGO_K_ENT"],
      vtarut_codigo_k_aut: dir["VTARUT_CODIGO_K_AUT"],
      vtarut_codigo_k_cob: dir["VTARUT_CODIGO_K_COB"],
      vtarut_codigo_k_simpre: dir["VTARUT_CODIGO_K_SIMPRE"],
      vtarut_codigo_k_siment: dir["VTARUT_CODIGO_K_SIMENT"],
      vtarut_codigo_k_simcob: dir["VTARUT_CODIGO_K_SIMCOB"],
      vtarut_codigo_k_simaut: dir["VTARUT_CODIGO_K_SIMAUT"],
      vtarut_codigo_k_sup: dir["VTARUT_CODIGO_K_SUP"],
      ctedir_celular: dir["CTEDIR_CELULAR"],
      ctedir_mail: dir["CTEDIR_MAIL"],
      ctedir_observaciones: dir["CTEDIR_OBSERVACIONES"],
      ctepfr_codigo_k: dir["CTEPFR_CODIGO_K"],
      cteclu_codigo_k: dir["CTECLU_CODIGO_K"],
      ctezni_codigo_k: dir["CTEZNI_CODIGO_K"],
      ctecor_codigo_k: dir["CTECOR_CODIGO_K"],
      condim_codigo_k: dir["CONDIM_CODIGO_K"],
      ctepaq_codigo_k: dir["CTEPAQ_CODIGO_K"],
      ctevie_codigo_k: dir["CTEVIE_CODIGO_K"],
      ctesvi_codigo_k: dir["CTESVI_CODIGO_K"],
      satcp_codigo_k: dir["SATCP_CODIGO_K"],
      satcol_codigo_k: dir["SATCOL_CODIGO_K"],
      c_estado_k: dir["C_ESTADO_K"],
      c_municipio_k: dir["C_MUNICIPIO_K"],
      c_localidad_k: dir["C_LOCALIDAD_K"],
      cfgest_codigo_k: dir["CFGEST_CODIGO_K"],
      ctedir_ivafrontera: dir["CTEDIR_IVAFRONTERA"],
      ctedir_secuencia: dir["CTEDIR_SECUENCIA"],
      ctedir_secuenciaent: dir["CTEDIR_SECUENCIAENT"],
      ctedir_reqgeo: dir["CTEDIR_REQGEO"],
      ctedir_distancia: dir["CTEDIR_DISTANCIA"],
      ctedir_novalidavencimiento: dir["CTEDIR_NOVALIDAVENCIMIENTO"],
      ctedir_edocred: dir["CTEDIR_EDOCRED"],
      ctedir_diascredito: dir["CTEDIR_DIASCREDITO"],
      ctedir_limitecredi: dir["CTEDIR_LIMITECREDI"],
      ctedir_tipopago: dir["CTEDIR_TIPOPAGO"],
      ctedir_tipodefacr: dir["CTEDIR_TIPODEFACR"],
      s_maqedo: dir["S_MAQEDO"],
      ctedir_creditoobs: dir["CTEDIR_CREDITOOBS"]
    }
  end

  defp parse_clasificacion(nil), do: nil
  defp parse_clasificacion(value) when is_binary(value) do
    upper = String.upcase(value)
    cond do
      String.contains?(upper, "LINGOTE") -> "ORO"
      String.contains?(upper, "DIAMANTE") -> "EXITO"
      String.contains?(upper, "BRONCE") -> "BRONCE"
      String.contains?(upper, "PLATA") -> "PLATA"
      true -> String.trim(value)
    end
  end
  defp parse_clasificacion(_), do: nil
end
