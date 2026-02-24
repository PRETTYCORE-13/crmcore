defmodule Prettycore.Catalogos do
  @moduledoc """
  Contexto para cargar catálogos desde la API REST EN_RESTHELPER
  para usar en los formularios de clientes.

  **Nota**: Este módulo consume datos desde la API REST en lugar de
  consultas directas a SQL Server.

  Base URL: https://s2.ecore.ninja:1522/SP/EN_RESTHELPER/
  """

  alias Prettycore.Api.Client, as: Api
  alias Prettycore.Api.Cache
  alias Prettycore.EncodingHelper
  alias Prettycore.PsqlRepo
  alias Prettycore.Map.Estado
  alias Prettycore.Map.Municipio
  alias Prettycore.Map.Localidad
  import Ecto.Query
  require Logger

  @doc """
  Precarga TODOS los catálogos al caché en paralelo.
  Se llama una vez al iniciar sesión.
  """
  def precargar_catalogos(token) do
    Logger.info("PRELOAD: Iniciando precarga de catálogos...")
    start = System.monotonic_time(:millisecond)

    # Lote 1A: CTE_CLIENTE - solo carga si no está en caché (evita OOM en logins concurrentes)
    batch1a = [
      Task.async(fn ->
        if :persistent_term.get(:cache_cte_cliente, nil) == nil do
          case Api.get_all("CTE_CLIENTE", token) do
            {:ok, data} -> :persistent_term.put(:cache_cte_cliente, data); :ok
            {:error, _} -> :ok
          end
        else
          :ok
        end
      end)
    ]

    run_batch(batch1a, "Lote 1A (clientes)")

    # Lote 1B: Direcciones y empresa - CTE_DIRECCION solo si no está en caché
    batch1b = [
      Task.async(fn ->
        if :persistent_term.get(:cache_cte_direccion, nil) == nil do
          case Api.get_all("CTE_DIRECCION", token) do
            {:ok, data} -> :persistent_term.put(:cache_cte_direccion, data); :ok
            {:error, _} -> :ok
          end
        else
          :ok
        end
      end),
      Task.async(fn ->
        case Api.get_all("SYS_EMPRESA", token) do
          {:ok, [empresa | _]} ->
            logo = Map.get(empresa, "SYSEMP_LOGOTIPO")
            if logo && logo != "" do
              formatted = if String.starts_with?(logo, "data:image"), do: logo, else: "data:image/png;base64,#{logo}"
              :persistent_term.put(:company_logo_cache, formatted)
            end
          _ -> :ok
        end
      end)
    ]

    run_batch(batch1b, "Lote 1B (dirs/empresa)")

    # Lote 2: Catálogos de formularios
    batch2 = [
      Task.async(fn -> listar_tipos_cliente(token) end),
      Task.async(fn -> listar_canales(token) end),
      Task.async(fn -> listar_regimenes(token) end),
      Task.async(fn -> listar_cadenas(token) end),
      Task.async(fn -> listar_paquetes_servicio(token) end)
    ]

    run_batch(batch2, "Lote 2 (catálogos 1)")

    # Lote 3: Catálogos SAT y más
    batch3 = [
      Task.async(fn -> listar_monedas(token) end),
      Task.async(fn -> listar_rutas(token) end),
      Task.async(fn -> listar_usos_cfdi(token) end),
      Task.async(fn -> listar_formas_pago(token) end),
      Task.async(fn -> listar_metodos_pago(token) end)
    ]

    run_batch(batch3, "Lote 3 (catálogos 2)")

    # Lote 4: Restantes
    batch4 = [
      Task.async(fn -> listar_regimenes_fiscales(token) end),
      Task.async(fn ->
        Cache.fetch({:all_subcanales, token}, fn ->
          case Api.get_all("CTE_SUBCANAL", token) do
            {:ok, rows} -> rows; {:error, _} -> []
          end
        end)
      end),
      Task.async(fn ->
        case Api.get_all("SYS_USUARIO", token) do
          {:ok, users} ->
            opts = users |> Enum.map(& &1["SYSUDN_CODIGO_K"]) |> Enum.reject(&(&1 in [nil, ""])) |> Enum.uniq() |> Enum.sort()
            :persistent_term.put(:cache_sysudn_opts, opts)
          {:error, _} -> :ok
        end
      end),
      Task.async(fn ->
        case Api.get_all("VTA_RUTA", token) do
          {:ok, rutas} ->
            opts = rutas |> Enum.map(& &1["VTARUT_CODIGO_K"]) |> Enum.reject(&(&1 in [nil, ""])) |> Enum.uniq() |> Enum.sort()
            :persistent_term.put(:cache_ruta_opts, opts)
          {:error, _} -> :ok
        end
      end)
    ]

    run_batch(batch4, "Lote 4 (restantes)")

    elapsed = System.monotonic_time(:millisecond) - start
    Logger.info("PRELOAD: Catálogos precargados en #{elapsed}ms (4 lotes secuenciales)")

    :ok
  end

  defp run_batch(tasks, label) do
    results = Task.yield_many(tasks, 20_000)

    failed =
      Enum.count(results, fn
        {_task, {:ok, _}} -> false
        {task, nil} ->
          Task.shutdown(task, :brutal_kill)
          true
        {_task, {:exit, _}} -> true
      end)

    if failed > 0 do
      Logger.warning("PRELOAD #{label}: #{failed}/#{length(tasks)} fallaron")
    else
      Logger.info("PRELOAD #{label}: #{length(tasks)} OK")
    end
  end

  def listar_tipos_cliente(token \\ nil) do
    Cache.fetch({:tipos_cliente, token}, fn ->
      case Api.get_tipos_cliente(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["CTETPO_DESCRIPCION"], row["CTETPO_CODIGO_K"]} end)
          |> Enum.sort_by(fn {nombre, _} -> nombre end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_canales(token \\ nil) do
    Cache.fetch({:canales, token}, fn ->
      case Api.get_canales(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> codigo = row["CTECAN_CODIGO_K"]; {codigo, codigo} end)
          |> Enum.uniq()
          |> Enum.sort()
        {:error, _} -> []
      end
    end)
  end

  def listar_subcanales(canal_codigo, token \\ nil)

  def listar_subcanales(canal_codigo, token) when is_binary(canal_codigo) do
    # Traer TODOS los subcanales una vez y filtrar en memoria
    all_subcanales = Cache.fetch({:all_subcanales, token}, fn ->
      case Api.get_all("CTE_SUBCANAL", token) do
        {:ok, rows} -> rows
        {:error, _} -> []
      end
    end)

    all_subcanales
    |> Enum.filter(fn row -> row["CTECAN_CODIGO_K"] == canal_codigo end)
    |> Enum.map(fn row -> {row["CTESCA_DESCRIPCION"], row["CTESCA_CODIGO_K"]} end)
    |> Enum.sort_by(fn {nombre, _} -> nombre end)
    |> EncodingHelper.convert_catalog_list()
  end

  def listar_subcanales(_, _), do: []

  def listar_regimenes(token \\ nil) do
    Cache.fetch({:regimenes, token}, fn ->
      case Api.get_regimenes(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["CTEREG_DESCRIPCION"], row["CTEREG_CODIGO_K"]} end)
          |> Enum.sort_by(fn {nombre, _} -> nombre end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_cadenas(token \\ nil) do
    Cache.fetch({:cadenas, token}, fn ->
      case Api.get_cadenas(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["CTECAD_DCOMERCIAL"], row["CTECAD_CODIGO_K"]} end)
          |> Enum.sort_by(fn {nombre, _} -> nombre end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_paquetes_servicio(token \\ nil) do
    Cache.fetch({:paquetes_servicio, token}, fn ->
      case Api.get_paquetes_servicio(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["CTEPAQ_DESCRIPCION"], row["CTEPAQ_CODIGO_K"]} end)
          |> Enum.sort_by(fn {nombre, _} -> nombre end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

#  def listar_transacciones(token \\ nil) do
#    Cache.fetch({:transacciones, token}, fn ->
      # Traer todas y filtrar por tipo "F" en memoria
#      case Api.get_all("SYS_TRANSAC", token) do
#        {:ok, rows} ->
#          rows
#          |> Enum.filter(fn row -> row["SYSTRA_TIPO"] == "F" end)
#          |> Enum.map(fn row -> {row["SYSTRA_DESCRIPCION"], row["SYSTRA_CODIGO_K"]} end)
#          |> Enum.sort_by(fn {nombre, _} -> nombre end)
#          |> EncodingHelper.convert_catalog_list()
#        {:error, _} -> []
#      end
#    end)
 # end

  def listar_monedas(token \\ nil) do
    Cache.fetch({:monedas, token}, fn ->
      case Api.get_monedas(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["CFGMON_DESCRIPCION"], row["CFGMON_CODIGO_K"]} end)
          |> Enum.sort_by(fn {_, codigo} -> codigo end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_estados(_token \\ nil) do
    Estado
    |> order_by([e], e.descripcion)
    |> PsqlRepo.all()
    |> Enum.map(fn e -> {e.descripcion, to_string(e.codigo_k)} end)
  end

  def listar_municipios(estado_codigo, _token \\ nil)

  def listar_municipios(estado_codigo, _token) when is_integer(estado_codigo) do
    listar_municipios(to_string(estado_codigo), nil)
  end

  def listar_municipios(estado_codigo, _token) when is_binary(estado_codigo) do
    estado_int = String.to_integer(estado_codigo)

    Municipio
    |> where([m], m.estado_codigo_k == ^estado_int)
    |> order_by([m], m.descripcion)
    |> PsqlRepo.all()
    |> Enum.map(fn m -> {m.descripcion, to_string(m.codigo_k)} end)
  rescue
    ArgumentError -> []
  end

  def listar_municipios(_, _), do: []

  def listar_localidades(estado_codigo, municipio_codigo, _token \\ nil)

  def listar_localidades(estado_codigo, municipio_codigo, _token)
      when is_integer(estado_codigo) or is_integer(municipio_codigo) do
    listar_localidades(to_string(estado_codigo), to_string(municipio_codigo), nil)
  end

  def listar_localidades(estado_codigo, municipio_codigo, _token)
      when is_binary(estado_codigo) and is_binary(municipio_codigo) do
    estado_int = String.to_integer(estado_codigo)
    municipio_int = String.to_integer(municipio_codigo)

    Localidad
    |> where([l], l.estado_codigo_k == ^estado_int and l.municipio_codigo_k == ^municipio_int)
    |> order_by([l], l.descripcion)
    |> PsqlRepo.all()
    |> Enum.map(fn l -> {l.descripcion, to_string(l.codigo_k)} end)
  rescue
    ArgumentError -> []
  end

  def listar_localidades(_, _, _), do: []

  def listar_rutas(token \\ nil) do
    Cache.fetch({:rutas, token}, fn ->
      case Api.get_rutas(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row -> {row["VTARUT_DESCRIPCION"], row["VTARUT_CODIGO_K"]} end)
          |> Enum.sort_by(fn {nombre, _} -> nombre end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_usos_cfdi(token \\ nil) do
    Cache.fetch({:usos_cfdi, token}, fn ->
      case Api.get_usos_cfdi(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row ->
            codigo = row["SAT_USO_CFDI_K"]
            nombre = row["SATUSO_CFDI_DESCRIPCION"]
            {" #{codigo} - #{nombre}", codigo}
          end)
          |> Enum.sort_by(fn {_, codigo} -> codigo end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_formas_pago(token \\ nil) do
    Cache.fetch({:formas_pago, token}, fn ->
      case Api.get_formas_pago(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row ->
            codigo = row["CTECLI_FORMAPAGO"]
            nombre = row["SATFP_DESCRIPCION"]
            {"#{codigo} - #{nombre}", codigo}
          end)
          |> Enum.sort_by(fn {_, codigo} -> codigo end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_metodos_pago(token \\ nil) do
    Cache.fetch({:metodos_pago, token}, fn ->
      case Api.get_metodos_pago(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row ->
            codigo = row["CFGMTP_CODIGO_K"]
            descripcion = row["CFGMTP_DESCRIPCION"]
            {"#{codigo} - #{descripcion}", codigo}
          end)
          |> Enum.sort_by(fn {_, codigo} -> codigo end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def listar_regimenes_fiscales(token \\ nil) do
    Cache.fetch({:regimenes_fiscales, token}, fn ->
      case Api.get_regimenes_fiscales(token) do
        {:ok, rows} ->
          rows
          |> Enum.map(fn row ->
            codigo = row["CFGREG_CODIGO_K"]
            nombre = row["CFGREG_DESCRIPCION"]
            {"#{codigo} - #{nombre}", codigo}
          end)
          |> Enum.sort_by(fn {_, codigo} -> codigo end)
          |> EncodingHelper.convert_catalog_list()
        {:error, _} -> []
      end
    end)
  end

  def buscar_por_cp(codigo_postal, _token \\ nil)

  def buscar_por_cp(codigo_postal, _token) when is_binary(codigo_postal) do
    case PsqlRepo.one(from l in Localidad, where: l.cp == ^codigo_postal, limit: 1) do
      nil ->
        {:error, :not_found}

      localidad ->
        estado = PsqlRepo.get(Estado, localidad.estado_codigo_k)

        municipio =
          PsqlRepo.one(
            from m in Municipio,
              where: m.estado_codigo_k == ^localidad.estado_codigo_k
                and m.codigo_k == ^localidad.municipio_codigo_k
          )

        {:ok, %{
          estado_codigo: to_string(localidad.estado_codigo_k),
          estado_nombre: estado && estado.descripcion,
          municipio_codigo: to_string(localidad.municipio_codigo_k),
          municipio_nombre: municipio && municipio.descripcion,
          localidad_codigo: to_string(localidad.codigo_k),
          localidad_nombre: localidad.descripcion
        }}
    end
  end

  def buscar_por_cp(_, _), do: {:error, :invalid_cp}
end
