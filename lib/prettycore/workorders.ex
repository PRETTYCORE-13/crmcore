defmodule Prettycore.Workorders do
  @moduledoc """
  Contexto para gestión de Work Orders usando API REST EN_RESTHELPER.

  Este módulo consume datos desde la API REST en lugar de
  consultas directas a SQL Server.

  Base URL: http://ecore.ath.cx:1405/SP/EN_RESTHELPER/
  """

  alias Prettycore.Api.Client, as: Api

  ## Encabezados (órdenes)

  @doc """
  Lista todas las work orders.
  """
  def list_enc(token \\ nil) do
    case Api.get_workorders(token) do
      {:ok, workorders} ->
        workorders
        |> Enum.map(&normalize_workorder/1)
        |> load_tipos(token)

      {:error, _} ->
        []
    end
  end

  @doc """
  Lists workorder headers with optional filters applied.

  ## Options
    * `:estado` - Filter by estado value (e.g., "por_aceptar" for estado == 100, "todas" for all)
    * `:sysudn` - Filter by sysudn value
    * `:usuario` - Filter by usuario value
    * `:fecha_desde` - Filter by fecha >= this date (ISO8601 string or Date)
    * `:fecha_hasta` - Filter by fecha <= this date (ISO8601 string or Date)

  ## Examples
      iex> list_enc_filtered(%{estado: "por_aceptar"})
      [%{...}, ...]

      iex> list_enc_filtered(%{sysudn: "100", fecha_desde: "2025-01-01"})
      [%{...}, ...]
  """
  def list_enc_filtered(filters \\ %{}, token \\ nil) do
    # Construir filtros para la API
    api_filters = build_api_filters(filters)

    case Api.get_filtered("XEN_WOKORDERENC", api_filters, token) do
      {:ok, workorders} ->
        workorders
        |> Enum.map(&normalize_workorder/1)
        |> filter_by_estado(filters[:estado])
        |> filter_by_fecha_desde(filters[:fecha_desde])
        |> filter_by_fecha_hasta(filters[:fecha_hasta])
        |> load_tipos(token)

      {:error, _} ->
        []
    end
  end

  @doc """
  Lists workorder headers with Flop-compatible pagination.

  ## Parameters
    * `flop_params` - Flop parameters including pagination, filters and sorting

  ## Examples
      iex> list_enc_with_flop(%{page: 1, page_size: 20})
      {:ok, {[%{...}, ...], %Flop.Meta{}}}
  """
  def list_enc_with_flop(flop_params \\ %{}, token \\ nil) do
    page = String.to_integer(flop_params["page"] || "1")
    page_size = String.to_integer(flop_params["page_size"] || "20")

    # Obtener filtros
    filters = %{
      estado: flop_params["estado"] || flop_params[:estado],
      sysudn: flop_params["sysudn"] || flop_params[:sysudn],
      usuario: flop_params["usuario"] || flop_params[:usuario],
      fecha_desde: flop_params["fecha_desde"] || flop_params[:fecha_desde],
      fecha_hasta: flop_params["fecha_hasta"] || flop_params[:fecha_hasta]
    }

    # Obtener todos los workorders filtrados
    workorders = list_enc_filtered(filters, token)

    # Aplicar paginación manual
    total_count = length(workorders)
    total_pages = max(ceil(total_count / page_size), 1)
    offset = (page - 1) * page_size

    workorders_paginados = workorders
    |> Enum.sort_by(& &1.folio, :desc)
    |> Enum.drop(offset)
    |> Enum.take(page_size)

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

    {:ok, {workorders_paginados, meta}}
  end

  ## Detalle (imágenes)

  @doc """
  Lista los detalles de una work order (imágenes).
  """
  def list_det(sysudn, systra, serie, folio, token \\ nil) do
    filters = %{
      "SYSUDN_CODIGO_K" => sysudn,
      "SYSTRA_CODIGO_K" => systra,
      "WOKE_SERIE_K" => serie,
      "WOKE_FOLIO_K" => folio
    }

    case Api.get_filtered("XEN_WOKORDERDET", filters, token) do
      {:ok, detalles} ->
        Enum.map(detalles, fn det ->
          %{
            concepto: det["WOKD_RENGLON_K"],
            descripcion: nil,
            image_url: det["WOKD_IMAGEN"]
          }
        end)

      {:error, error} ->
        IO.inspect(error, label: "error list_det")
        []
    end
  end

  ## Private functions

  defp build_api_filters(filters) do
    filters
    |> Enum.reduce(%{}, fn
      {:sysudn, value}, acc when is_binary(value) and value != "" ->
        Map.put(acc, "SYSUDN_CODIGO_K", value)

      {:usuario, value}, acc when is_binary(value) and value != "" ->
        Map.put(acc, "WOKE_USUARIO", value)

      _, acc ->
        acc
    end)
  end

  defp filter_by_estado(workorders, nil), do: workorders
  defp filter_by_estado(workorders, ""), do: workorders
  defp filter_by_estado(workorders, "todas"), do: workorders

  defp filter_by_estado(workorders, "por_aceptar") do
    Enum.filter(workorders, fn wo -> wo.estado == 100 end)
  end

  defp filter_by_estado(workorders, estado) when is_integer(estado) do
    Enum.filter(workorders, fn wo -> wo.estado == estado end)
  end

  defp filter_by_estado(workorders, estado) when is_binary(estado) do
    case Integer.parse(estado) do
      {int_estado, ""} -> filter_by_estado(workorders, int_estado)
      _ -> workorders
    end
  end

  defp filter_by_fecha_desde(workorders, nil), do: workorders
  defp filter_by_fecha_desde(workorders, ""), do: workorders

  defp filter_by_fecha_desde(workorders, fecha_desde) do
    date = parse_date(fecha_desde)

    if date do
      naive_datetime = NaiveDateTime.new!(date, ~T[00:00:00])
      Enum.filter(workorders, fn wo ->
        wo.fecha && NaiveDateTime.compare(wo.fecha, naive_datetime) in [:gt, :eq]
      end)
    else
      workorders
    end
  end

  defp filter_by_fecha_hasta(workorders, nil), do: workorders
  defp filter_by_fecha_hasta(workorders, ""), do: workorders

  defp filter_by_fecha_hasta(workorders, fecha_hasta) do
    date = parse_date(fecha_hasta)

    if date do
      naive_datetime = NaiveDateTime.new!(date, ~T[23:59:59])
      Enum.filter(workorders, fn wo ->
        wo.fecha && NaiveDateTime.compare(wo.fecha, naive_datetime) in [:lt, :eq]
      end)
    else
      workorders
    end
  end

  defp parse_date(%Date{} = date), do: date
  defp parse_date(%NaiveDateTime{} = naive_dt), do: NaiveDateTime.to_date(naive_dt)
  defp parse_date(%DateTime{} = dt), do: DateTime.to_date(dt)

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_date(_), do: nil

  defp normalize_workorder(wo) do
    %{
      sysudn: wo["SYSUDN_CODIGO_K"],
      systra: wo["SYSTRA_CODIGO_K"],
      serie: wo["WOKE_SERIE_K"],
      folio: wo["WOKE_FOLIO_K"],
      referencia: wo["WOKE_REFERENCIA"],
      fecha: parse_datetime(wo["S_FECHA"]),
      estado: wo["S_MAQEDO"],
      usuario: wo["WOKE_USUARIO"],
      woktpo_codigo_k: wo["WOKTPO_CODIGO_K"],
      descripcion: wo["WOKE_DESCRIPCION"],
      tipo: nil  # Se carga después
    }
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case NaiveDateTime.from_iso8601(datetime_string) do
      {:ok, dt} -> dt
      {:error, _} -> nil
    end
  end
  defp parse_datetime(%NaiveDateTime{} = dt), do: dt
  defp parse_datetime(_), do: nil

  defp load_tipos(workorders, token) do
    # Obtener todos los tipos de workorder
    tipos_map = case Api.get_workorder_tipos(token) do
      {:ok, tipos} ->
        Enum.into(tipos, %{}, fn tipo ->
          {tipo["WOKTPO_CODIGO_K"], %{
            codigo: tipo["WOKTPO_CODIGO_K"],
            descripcion: tipo["WOKTPO_DESCRIPCION"]
          }}
        end)

      {:error, _} ->
        %{}
    end

    # Asignar tipo a cada workorder
    Enum.map(workorders, fn wo ->
      tipo = Map.get(tipos_map, wo.woktpo_codigo_k)
      %{wo | tipo: tipo}
    end)
  end
end
