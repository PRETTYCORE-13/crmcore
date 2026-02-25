defmodule Prettycore.MapSeeder do
  @moduledoc """
  GenServer que siembra las tablas map_estados, map_municipios y map_localidades
  en PostgreSQL desde la API externa, una sola vez al arrancar la app.

  Si las tablas ya tienen datos no hace nada.
  """
  use GenServer
  require Logger

  alias Prettycore.PsqlRepo
  alias Prettycore.Map.Estado
  alias Prettycore.Map.Municipio
  alias Prettycore.Map.Localidad

  @timeout_large 120_000

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    # Dar tiempo a que PsqlRepo y la config estén listos antes de intentar seed
    Process.send_after(self(), :seed, 3_000)
    {:ok, :pending}
  end

  @impl true
  def handle_info(:seed, _state) do
    seed_if_empty()
    {:noreply, :done}
  end

  # ------------------------------------------------
  # Lógica principal
  # ------------------------------------------------

  defp seed_if_empty do
    count = PsqlRepo.aggregate(Estado, :count, :codigo_k)

    if count == 0 do
      Logger.info("MapSeeder: tablas de geografía vacías — iniciando seed desde API...")
      seed_estados()
      seed_municipios()
      seed_localidades()
      Logger.info("MapSeeder: seed completado")
    else
      Logger.info("MapSeeder: ya existen #{count} estados en Postgres — skip")
    end
  rescue
    e ->
      Logger.error("MapSeeder: error inesperado: #{inspect(e)}")
  end

  # ------------------------------------------------
  # Seed estados
  # ------------------------------------------------

  defp seed_estados do
    Logger.info("MapSeeder: obteniendo MAP_ESTADO desde API...")

    case fetch_table("MAP_ESTADO") do
      {:ok, rows} when is_list(rows) and length(rows) > 0 ->
        entries =
          rows
          |> Enum.map(fn r ->
            %{
              codigo_k: to_int(r["MAPEDO_CODIGO_K"]),
              descripcion: r["MAPEDO_DESCRIPCION"] || ""
            }
          end)
          |> Enum.reject(fn %{codigo_k: c} -> is_nil(c) end)

        {count, _} = PsqlRepo.insert_all(Estado, entries, on_conflict: :nothing)
        Logger.info("MapSeeder: #{count} estados insertados")

      {:ok, []} ->
        Logger.warning("MapSeeder: MAP_ESTADO devolvió 0 registros")

      {:error, reason} ->
        Logger.error("MapSeeder: error obteniendo MAP_ESTADO: #{inspect(reason)}")
    end
  end

  # ------------------------------------------------
  # Seed municipios
  # ------------------------------------------------

  defp seed_municipios do
    Logger.info("MapSeeder: obteniendo MAP_MUNICIPIO desde API...")

    case fetch_table("MAP_MUNICIPIO") do
      {:ok, rows} when is_list(rows) and length(rows) > 0 ->
        entries =
          rows
          |> Enum.map(fn r ->
            %{
              estado_codigo_k: to_int(r["MAPEDO_CODIGO_K"]),
              codigo_k: to_int(r["MAPMUN_CODIGO_K"]),
              descripcion: r["MAPMUN_DESCRIPCION"] || ""
            }
          end)
          |> Enum.reject(fn %{estado_codigo_k: e, codigo_k: c} -> is_nil(e) or is_nil(c) end)

        total =
          entries
          |> Enum.chunk_every(500)
          |> Enum.reduce(0, fn chunk, acc ->
            {n, _} = PsqlRepo.insert_all(Municipio, chunk, on_conflict: :nothing)
            acc + n
          end)

        Logger.info("MapSeeder: #{total} municipios insertados")

      {:ok, []} ->
        Logger.warning("MapSeeder: MAP_MUNICIPIO devolvió 0 registros")

      {:error, reason} ->
        Logger.error("MapSeeder: error obteniendo MAP_MUNICIPIO: #{inspect(reason)}")
    end
  end

  # ------------------------------------------------
  # Seed localidades
  # ------------------------------------------------

  defp seed_localidades do
    Logger.info("MapSeeder: obteniendo MAP_LOCALIDAD desde API (puede tardar)...")

    case fetch_table_large("MAP_LOCALIDAD") do
      {:ok, rows} when is_list(rows) and length(rows) > 0 ->
        entries =
          rows
          |> Enum.map(fn r ->
            %{
              estado_codigo_k: to_int(r["MAPEDO_CODIGO_K"]),
              municipio_codigo_k: to_int(r["MAPMUN_CODIGO_K"]),
              codigo_k: to_int(r["MAPLOC_CODIGO_K"]),
              descripcion: r["MAPLOC_DESCRIPCION"] || "",
              cp: r["MAPLOC_CP"]
            }
          end)
          |> Enum.reject(fn %{estado_codigo_k: e, municipio_codigo_k: m, codigo_k: c} ->
            is_nil(e) or is_nil(m) or is_nil(c)
          end)

        total =
          entries
          |> Enum.chunk_every(500)
          |> Enum.reduce(0, fn chunk, acc ->
            {n, _} = PsqlRepo.insert_all(Localidad, chunk, on_conflict: :nothing)
            acc + n
          end)

        Logger.info("MapSeeder: #{total} localidades insertadas")

      {:ok, []} ->
        Logger.warning("MapSeeder: MAP_LOCALIDAD devolvió 0 registros")

      {:error, reason} ->
        Logger.error("MapSeeder: error obteniendo MAP_LOCALIDAD: #{inspect(reason)}")
    end
  end

  # ------------------------------------------------
  # HTTP helpers
  # ------------------------------------------------

  defp fetch_table(table) do
    Prettycore.Api.Client.get_all(table, nil)
  end

  defp fetch_table_large(table) do
    url = "#{Prettycore.Api.Client.base_url()}/#{table}"
    token = Prettycore.Api.Client.service_token()

    headers = [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    case Req.get(url, headers: headers, receive_timeout: @timeout_large, retry: false) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        cond do
          is_list(body) -> {:ok, body}
          is_map(body) -> {:ok, body}
          is_binary(body) ->
            case Jason.decode(body) do
              {:ok, data} -> {:ok, data}
              {:error, _} -> {:error, :parse_error}
            end
          true -> {:ok, body}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:connection_error, reason}}
    end
  end

  # ------------------------------------------------
  # Helpers
  # ------------------------------------------------

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> nil
    end
  end
  defp to_int(_), do: nil
end
