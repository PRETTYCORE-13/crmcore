defmodule Prettycore.Api.Client do
  @moduledoc """
  Cliente HTTP centralizado para consumir la API REST EN_RESTHELPER.

  Base URL: http://ecore.ath.cx:1405/SP/EN_RESTHELPER/

  Todas las tablas soportadas:
  - CTE_CLIENTE, CTE_DIRECCION
  - SYS_USUARIO, XEN_SYS_USUARIO
  - XEN_WOKORDERENC, XEN_WOKORDERTIPO, XEN_WOKORDERDET
  - CTE_TIPO, CTE_CANAL, CTE_SUBCANAL, CTE_CADENA, CTE_PAQUETESERV, CTE_REGIMEN
  - SYS_TRANSAC, CFG_MONEDA, VTA_RUTA
  - MAP_ESTADO, MAP_MUNICIPIO, MAP_LOCALIDAD
  - CFG_USOCFDISAT, CFG_FORMAPAGO_SAT, CFG_METODOPAGO, CFG_REGIMENFISCAL_SAT
  """
  require Logger

  @base_url "http://ecore.ath.cx:1405/SP/EN_RESTHELPER"
  @timeout 30_000

  # ============================================================
  # PUBLIC API - GET (SELECT)
  # ============================================================

  @doc """
  Obtiene todos los registros de una tabla.

  ## Ejemplos
      iex> Prettycore.Api.Client.get_all("CTE_TIPO")
      {:ok, [%{"CTETPO_CODIGO_K" => "100", ...}, ...]}

      iex> Prettycore.Api.Client.get_all("CTE_TIPO", "bearer_token")
      {:ok, [%{"CTETPO_CODIGO_K" => "100", ...}, ...]}
  """
  def get_all(table, auth_token \\ nil) when is_binary(table) do
    url = "#{@base_url}/#{table}"
    do_get(url, auth_token)
  end

  @doc """
  Obtiene registros filtrados de una tabla.
  Los filtros se envían en el body del POST request.

  ## Ejemplos
      iex> Prettycore.Api.Client.get_filtered("CTE_SUBCANAL", %{"CTECAN_CODIGO_K" => "01"})
      {:ok, [%{...}, ...]}
  """
  def get_filtered(table, filters, auth_token \\ nil) when is_binary(table) and is_map(filters) do
    url = "#{@base_url}/#{table}"
    do_post(url, filters, auth_token)
  end

  @doc """
  Obtiene un registro por su clave primaria.

  ## Ejemplos
      iex> Prettycore.Api.Client.get_by_id("CTE_CLIENTE", "CTECLI_CODIGO_K", "0001")
      {:ok, %{...}}
  """
  def get_by_id(table, pk_field, pk_value, auth_token \\ nil) do
    get_filtered(table, %{pk_field => pk_value}, auth_token)
    |> case do
      {:ok, [record | _]} -> {:ok, record}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Ejecuta una consulta SQL personalizada vía API (si está soportado).
  """
  def query(sql, auth_token \\ nil) when is_binary(sql) do
    url = "#{@base_url}/query"
    do_post(url, %{sql: sql}, auth_token)
  end

  # ============================================================
  # PUBLIC API - POST/PUT/DELETE
  # ============================================================

  @doc """
  Crea un nuevo registro en una tabla.
  """
  def create(table, data, auth_token \\ nil) do
    url = "#{@base_url}/#{table}"
    do_post(url, data, auth_token)
  end

  @doc """
  Actualiza un registro existente.
  """
  def update(table, data, auth_token \\ nil) do
    url = "#{@base_url}/#{table}"
    do_put(url, data, auth_token)
  end

  @doc """
  Elimina un registro.
  """
  def delete(table, pk_field, pk_value, auth_token \\ nil) do
    url = "#{@base_url}/#{table}?#{pk_field}=#{URI.encode_www_form(to_string(pk_value))}"
    do_delete(url, auth_token)
  end

  # ============================================================
  # HELPERS ESPECÍFICOS POR TABLA
  # ============================================================

  # --- Catálogos ---
  # Todas las funciones helper ahora soportan un token opcional como último parámetro

  def get_tipos_cliente(token \\ nil), do: get_all("CTE_TIPO", token)
  def get_canales(token \\ nil), do: get_all("CTE_CANAL", token)
  def get_subcanales(canal_codigo, token \\ nil), do: get_filtered("CTE_SUBCANAL", %{"CTECAN_CODIGO_K" => canal_codigo}, token)
  def get_regimenes(token \\ nil), do: get_all("CTE_REGIMEN", token)
  def get_cadenas(token \\ nil), do: get_all("CTE_CADENA", token)
  def get_paquetes_servicio(token \\ nil), do: get_all("CTE_PAQUETESERV", token)
  def get_transacciones(token \\ nil), do: get_filtered("SYS_TRANSAC", %{"SYSTRA_TIPO" => "F"}, token)
  def get_monedas(token \\ nil), do: get_all("CFG_MONEDA", token)
  def get_rutas(token \\ nil), do: get_all("VTA_RUTA", token)

  # --- Ubicaciones ---

  @spec get_estados(any()) ::
          {:error,
           {:connection_error,
            %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()}}
           | {:http_error, non_neg_integer(), any()}}
          | {:ok, any()}
  def get_estados(token \\ nil), do: get_all("MAP_ESTADO", token)
  def get_municipios(estado_codigo, token \\ nil), do: get_filtered("MAP_MUNICIPIO", %{"MAPEDO_CODIGO_K" => estado_codigo}, token)
  def get_localidades(estado_codigo, municipio_codigo, token \\ nil) do
    get_filtered("MAP_LOCALIDAD", %{
      "MAPEDO_CODIGO_K" => estado_codigo,
      "MAPMUN_CODIGO_K" => municipio_codigo
    }, token)
  end

  # --- SAT ---

  def get_usos_cfdi(token \\ nil), do: get_all("CFG_USOCFDISAT", token)
  def get_formas_pago(token \\ nil), do: get_all("CFG_FORMAPAGO_SAT", token)
  def get_metodos_pago(token \\ nil), do: get_all("CFG_METODOPAGO", token)
  def get_regimenes_fiscales(token \\ nil), do: get_all("CFG_REGIMENFISCAL_SAT", token)

  # --- Clientes ---

  def get_clientes(token \\ nil), do: get_all("CTE_CLIENTE", token)
  def get_cliente(codigo, token \\ nil), do: get_by_id("CTE_CLIENTE", "CTECLI_CODIGO_K", codigo, token)
  def get_direcciones_cliente(cliente_codigo, token \\ nil) do
    get_filtered("CTE_DIRECCION", %{"CTECLI_CODIGO_K" => cliente_codigo}, token)
  end

  # --- Usuarios ---

  def get_usuarios(token \\ nil), do: get_all("SYS_USUARIO", token)
  def get_usuario(codigo, token \\ nil), do: get_by_id("SYS_USUARIO", "SYSUSR_CODIGO_K", codigo, token)
  def get_xen_usuarios(token \\ nil), do: get_all("XEN_SYS_USUARIO", token)
  def get_xen_usuario(codigo, token \\ nil), do: get_by_id("XEN_SYS_USUARIO", "SYSUSR_CODIGO_K", codigo, token)

  @doc """
  Obtiene las credenciales de autenticación para el Usuario FROG.
  Envía: {"FG_USUARIO": "usuario_frog"}
  Recibe: {"SYSUSR_PASSWORD": "password_para_api"}
  """
  def get_frog_credentials(frog_usuario) when is_binary(frog_usuario) do
    url = "#{@base_url}/REST_USUARIO"
    data = %{"FG_USUARIO" => frog_usuario}

    Logger.debug("API FROG AUTH: #{url} with user #{frog_usuario}")

    # Token fijo para autenticar el endpoint REST_USUARIO
    auth_token = "IFcRzSfaBG6ycnpWzThyfEdKHglK14tlZylvRhOhlQ1fDHobmveKk6JowcU/BhCquBlqQv7zkrLIUYvFZmQZqHdqNiLptzCBf5wT826XpY4="

    headers = [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{auth_token}"}
    ]

    body = Jason.encode!(data)

    case Req.post(url, body: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        case parse_response(resp_body) do
          {:ok, %{"SYSUSR_PASSWORD" => password}} when is_binary(password) ->
            {:ok, password}

          {:ok, [%{"SYSUSR_PASSWORD" => password} | _]} when is_binary(password) ->
            {:ok, password}

          {:ok, other} ->
            Logger.error("FROG AUTH unexpected response: #{inspect(other)}")
            {:error, :invalid_response}
        end

      {:ok, %Req.Response{status: 401, body: resp_body}} ->
        Logger.error("FROG AUTH error 401: #{inspect(resp_body)}")
        {:error, :unauthorized}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        Logger.error("FROG AUTH error #{status}: #{inspect(resp_body)}")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        Logger.error("FROG AUTH connection error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  # --- Work Orders ---

  def get_workorders(token \\ nil), do: get_all("XEN_WOKORDERENC", token)
  def get_workorder(codigo, token \\ nil), do: get_by_id("XEN_WOKORDERENC", "XENWOE_CODIGO_K", codigo, token)
  def get_workorder_tipos(token \\ nil), do: get_all("XEN_WOKORDERTIPO", token)
  def get_workorder_detalles(workorder_codigo, token \\ nil) do
    get_filtered("XEN_WOKORDERDET", %{"XENWOE_CODIGO_K" => workorder_codigo}, token)
  end

  # ============================================================
  # PRIVATE FUNCTIONS
  # ============================================================

  defp do_get(url, auth_token) do
    Logger.debug("API GET: #{url}")

    headers = build_headers(auth_token)

    case Req.get(url, headers: headers, receive_timeout: @timeout) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        parse_response(body)

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("API GET error #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("API GET connection error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp do_post(url, data, auth_token) do
    Logger.debug("API POST: #{url}")

    headers = build_headers(auth_token)
    body = Jason.encode!(data)

    case Req.post(url, body: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        parse_response(resp_body)

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        Logger.error("API POST error #{status}: #{inspect(resp_body)}")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        Logger.error("API POST connection error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp do_put(url, data, auth_token) do
    Logger.debug("API PUT: #{url}")

    headers = build_headers(auth_token)
    body = Jason.encode!(data)

    case Req.put(url, body: body, headers: headers, receive_timeout: @timeout) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        parse_response(resp_body)

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        Logger.error("API PUT error #{status}: #{inspect(resp_body)}")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        Logger.error("API PUT connection error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp do_delete(url, auth_token) do
    Logger.debug("API DELETE: #{url}")

    headers = build_headers(auth_token)

    case Req.delete(url, headers: headers, receive_timeout: @timeout) do
      {:ok, %Req.Response{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        Logger.error("API DELETE error #{status}: #{inspect(resp_body)}")
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        Logger.error("API DELETE connection error: #{inspect(reason)}")
        {:error, {:connection_error, reason}}
    end
  end

  defp build_headers(nil) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ]
  end

  defp build_headers(auth_token) do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{auth_token}"}
    ]
  end

  defp build_query_string(filters) do
    filters
    |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(to_string(v))}" end)
    |> Enum.join("&")
  end

  defp parse_response(body) when is_list(body), do: {:ok, body}
  defp parse_response(body) when is_map(body), do: {:ok, body}
  defp parse_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:ok, body}
    end
  end
  defp parse_response(body), do: {:ok, body}
end
