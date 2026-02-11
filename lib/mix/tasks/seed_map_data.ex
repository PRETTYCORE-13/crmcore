defmodule Mix.Tasks.SeedMapData do
  @moduledoc """
  Tarea única para poblar las tablas map_estados, map_municipios y map_localidades
  con datos desde la API REST EN_RESTHELPER.

  Uso:
      mix seed_map_data
  """
  use Mix.Task

  alias Prettycore.Api.Client, as: Api
  alias Prettycore.PsqlRepo
  alias Prettycore.Map.{Estado, Municipio, Localidad}
  alias Prettycore.EncodingHelper

  require Logger

  @shortdoc "Siembra datos geográficos (estados, municipios, localidades) desde API REST a PostgreSQL"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    token = Api.service_token()

    seed_estados(token)
    seed_municipios(token)
    seed_localidades(token)

    Logger.info("Siembra de datos geográficos completada.")
  end

  defp seed_estados(token) do
    Logger.info("Obteniendo MAP_ESTADO desde API...")

    case Api.get_all("MAP_ESTADO", token) do
      {:ok, rows} ->
        Logger.info("Insertando #{length(rows)} estados...")

        Enum.each(rows, fn row ->
          %Estado{
            codigo_k: row["MAPEDO_CODIGO_K"],
            descripcion: EncodingHelper.latin1_to_utf8(row["MAPEDO_DESCRIPCION"])
          }
          |> PsqlRepo.insert!(
            on_conflict: :replace_all,
            conflict_target: [:codigo_k]
          )
        end)

        Logger.info("Estados insertados correctamente.")

      {:error, reason} ->
        Logger.error("Error obteniendo estados: #{inspect(reason)}")
    end
  end

  defp seed_municipios(token) do
    Logger.info("Obteniendo MAP_MUNICIPIO desde API...")

    case Api.get_all("MAP_MUNICIPIO", token) do
      {:ok, rows} ->
        Logger.info("Insertando #{length(rows)} municipios...")

        entries =
          Enum.map(rows, fn row ->
            %{
              estado_codigo_k: row["MAPEDO_CODIGO_K"],
              codigo_k: row["MAPMUN_CODIGO_K"],
              descripcion: EncodingHelper.latin1_to_utf8(row["MAPMUN_DESCRIPCION"])
            }
          end)

        entries
        |> Enum.chunk_every(1000)
        |> Enum.each(fn batch ->
          PsqlRepo.insert_all(Municipio, batch,
            on_conflict: :replace_all,
            conflict_target: [:estado_codigo_k, :codigo_k]
          )
        end)

        Logger.info("Municipios insertados correctamente.")

      {:error, reason} ->
        Logger.error("Error obteniendo municipios: #{inspect(reason)}")
    end
  end

  defp seed_localidades(token) do
    Logger.info("Obteniendo MAP_LOCALIDAD desde API...")

    case Api.get_all("MAP_LOCALIDAD", token) do
      {:ok, rows} ->
        Logger.info("Insertando #{length(rows)} localidades...")

        entries =
          Enum.map(rows, fn row ->
            %{
              estado_codigo_k: row["MAPEDO_CODIGO_K"],
              municipio_codigo_k: row["MAPMUN_CODIGO_K"],
              codigo_k: row["MAPLOC_CODIGO_K"],
              descripcion: EncodingHelper.latin1_to_utf8(row["MAPLOC_DESCRIPCION"]),
              cp: row["MAPLOC_CP_K"]
            }
          end)

        entries
        |> Enum.chunk_every(1000)
        |> Enum.each(fn batch ->
          PsqlRepo.insert_all(Localidad, batch,
            on_conflict: :replace_all,
            conflict_target: [:estado_codigo_k, :municipio_codigo_k, :codigo_k]
          )
        end)

        Logger.info("Localidades insertadas correctamente.")

      {:error, reason} ->
        Logger.error("Error obteniendo localidades: #{inspect(reason)}")
    end
  end
end
