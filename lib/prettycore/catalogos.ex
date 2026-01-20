defmodule Prettycore.Catalogos do
  @moduledoc """
  Contexto para cargar catálogos desde la base de datos
  para usar en los formularios de clientes.

  **Nota sobre encoding**: Este módulo usa `EncodingHelper` para convertir
  datos Latin-1 de columnas VARCHAR a UTF-8, evitando errores de
  `Jason.EncodeError` en LiveView con caracteres como "ó", "ñ", "á".

  **TODO**: Migrar columnas VARCHAR a NVARCHAR en SQL Server para eliminar
  la necesidad de conversión manual. Ver ENCODING_ISSUE_PROPOSAL.md
  """

  alias Prettycore.Repo
  alias Prettycore.EncodingHelper

  @doc """
  Obtiene la lista de tipos de cliente
  """
  def listar_tipos_cliente do
    query = """
    SELECT CTETPO_CODIGO_K as codigo, CTETPO_DESCRIPCION as nombre
    FROM CTE_TIPO
    ORDER BY CTETPO_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de canales
  """
  def listar_canales do
    query = """
    SELECT DISTINCT CTECAN_CODIGO_K as codigo
    FROM CTE_SUBCANAL
    ORDER BY CTECAN_CODIGO_K
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        Enum.map(rows, fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          codigo = row_map["codigo"]
          {codigo, codigo}
        end)

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de subcanales para un canal específico
  """
  def listar_subcanales(canal_codigo) when is_binary(canal_codigo) do
    query = """
    SELECT CTESCA_CODIGO_K as codigo, CTESCA_DESCRIPCION as nombre
    FROM CTE_SUBCANAL
    WHERE CTECAN_CODIGO_K = @1
    ORDER BY CTESCA_DESCRIPCION
    """

    case Repo.query(query, [canal_codigo]) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  def listar_subcanales(_), do: []

  @doc """
  Obtiene la lista de regímenes
  """
  def listar_regimenes do
    query = """
    SELECT CTEREG_CODIGO_K as codigo, CTEREG_DESCRIPCION as nombre
    FROM CTE_REGIMEN
    ORDER BY CTEREG_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de cadenas
  """
  def listar_cadenas do
    query = """
    SELECT CTECAD_CODIGO_K as codigo, CTECAD_DCOMERCIAL as nombre
    FROM CTE_CADENA
    ORDER BY CTECAD_DCOMERCIAL
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de paquetes de servicio
  """
  def listar_paquetes_servicio do
    query = """
    SELECT CTEPAQ_CODIGO_K as codigo, CTEPAQ_DESCRIPCION as nombre
    FROM CTE_PAQUETESERV
    ORDER BY CTEPAQ_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de transacciones
  """
  def listar_transacciones do
    query = """
    SELECT SYSTRA_CODIGO_K as codigo, SYSTRA_DESCRIPCION as nombre
    FROM SYS_TRANSAC
    WHERE SYSTRA_TIPO = 'F'
    ORDER BY SYSTRA_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de monedas
  """
  def listar_monedas do
    query = """
    SELECT CFGMON_CODIGO_K as codigo, CFGMON_DESCRIPCION as nombre
    FROM CFG_MONEDA
    ORDER BY CFGMON_CODIGO_K
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de estados (para direcciones)
  """
  def listar_estados do
    query = """
    SELECT MAPEDO_CODIGO_K as codigo, MAPEDO_DESCRIPCION as nombre
    FROM MAP_ESTADO
    ORDER BY MAPEDO_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], to_string(row_map["codigo"])}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de municipios para un estado específico
  """
  def listar_municipios(estado_codigo) when is_integer(estado_codigo) do
    listar_municipios(to_string(estado_codigo))
  end

  def listar_municipios(estado_codigo) when is_binary(estado_codigo) do
    query = """
    SELECT MAPMUN_CODIGO_K as codigo, MAPMUN_DESCRIPCION as nombre
    FROM MAP_MUNICIPIO
    WHERE MAPEDO_CODIGO_K = @1
    ORDER BY MAPMUN_DESCRIPCION
    """

    case Repo.query(query, [estado_codigo]) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], to_string(row_map["codigo"])}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  def listar_municipios(_), do: []

  @doc """
  Obtiene la lista de localidades para un estado y municipio específicos
  """
  def listar_localidades(estado_codigo, municipio_codigo)
      when is_integer(estado_codigo) or is_integer(municipio_codigo) do
    listar_localidades(to_string(estado_codigo), to_string(municipio_codigo))
  end

  def listar_localidades(estado_codigo, municipio_codigo)
      when is_binary(estado_codigo) and is_binary(municipio_codigo) do
    query = """
    SELECT MAPLOC_CODIGO_K as codigo, MAPLOC_DESCRIPCION as nombre
    FROM MAP_LOCALIDAD
    WHERE MAPEDO_CODIGO_K = @1 AND MAPMUN_CODIGO_K = @2
    ORDER BY MAPLOC_DESCRIPCION
    """

    case Repo.query(query, [estado_codigo, municipio_codigo]) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], to_string(row_map["codigo"])}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  def listar_localidades(_, _), do: []

  @doc """
  Obtiene la lista de rutas
  """
  def listar_rutas do
    query = """
    SELECT VTARUT_CODIGO_K as codigo, VTARUT_DESCRIPCION as nombre
    FROM VTA_RUTA
    ORDER BY VTARUT_DESCRIPCION
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {row_map["nombre"], row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de usos de CFDI SAT
  """
  def listar_usos_cfdi do
    query = """
    SELECT SAT_USO_CFDI_K as codigo, SATUSO_CFDI_DESCRIPCION as nombre
    FROM CFG_USOCFDISAT
    ORDER BY SAT_USO_CFDI_K
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {" #{row_map["codigo"]} - #{row_map["nombre"]}", row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de formas de pago SAT
  """
  def listar_formas_pago do
    query = """
    SELECT CTECLI_FORMAPAGO as codigo, SATFP_DESCRIPCION as nombre
    FROM CFG_FORMAPAGO_SAT
    ORDER BY CTECLI_FORMAPAGO
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {"#{row_map["codigo"]} - #{row_map["nombre"]}", row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de métodos de pago SAT
  """
  def listar_metodos_pago do
    query = """
    SELECT
      CFGMTP_CODIGO_K as codigo,
      CFGMTP_DESCRIPCION as descripcion
    FROM
      CFG_METODOPAGO
    ORDER BY CFGMTP_CODIGO_K
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {"#{row_map["codigo"]} - #{row_map["descripcion"]}", row_map["codigo"]}
        end)
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene la lista de regímenes fiscales SAT
  """
  def listar_regimenes_fiscales do
    query = """
    SELECT CFGREG_CODIGO_K as codigo, CFGREG_DESCRIPCION as nombre
    FROM CFG_REGIMENFISCAL_SAT
    ORDER BY SATREG_CODIGO_K
    """

    case Repo.query(query) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          row_map = Enum.zip(columns, row) |> Enum.into(%{})
          {"#{row_map["codigo"]} - #{row_map["nombre"]}", row_map["codigo"]}
        end)
        # Convert Latin-1 to UTF-8
        |> EncodingHelper.convert_catalog_list()

      {:error, _} ->
        []
    end
  end

  @doc """
  Busca localidad por código postal y retorna datos de ubicación
  """
  def buscar_por_cp(codigo_postal) when is_binary(codigo_postal) do
    query = """
    SELECT TOP 1
      e.MAPEDO_CODIGO_K as estado_codigo,
      e.MAPEDO_DESCRIPCION as estado_nombre,
      m.MAPMUN_CODIGO_K as municipio_codigo,
      m.MAPMUN_DESCRIPCION as municipio_nombre,
      l.MAPLOC_CODIGO_K as localidad_codigo,
      l.MAPLOC_DESCRIPCION as localidad_nombre
    FROM MAP_LOCALIDAD l
    INNER JOIN MAP_ESTADO e ON l.MAPEDO_CODIGO_K = e.MAPEDO_CODIGO_K
    INNER JOIN MAP_MUNICIPIO m ON l.MAPEDO_CODIGO_K = m.MAPEDO_CODIGO_K
      AND l.MAPMUN_CODIGO_K = m.MAPMUN_CODIGO_K
    WHERE l.MAPLOC_CP_K = @1
    """

    case Repo.query(query, [codigo_postal]) do
      {:ok, %{rows: [row], columns: columns}} ->
        row_map = Enum.zip(columns, row) |> Enum.into(%{})

        # Convert Latin-1 names to UTF-8
        result =
          %{
            estado_codigo: to_string(row_map["estado_codigo"]),
            estado_nombre: row_map["estado_nombre"],
            municipio_codigo: to_string(row_map["municipio_codigo"]),
            municipio_nombre: row_map["municipio_nombre"],
            localidad_codigo: to_string(row_map["localidad_codigo"]),
            localidad_nombre: row_map["localidad_nombre"]
          }
          # Convert all name fields to UTF-8
          |> EncodingHelper.convert_map()

        {:ok, result}

      _ ->
        {:error, :not_found}
    end
  end

  def buscar_por_cp(_), do: {:error, :invalid_cp}
end
