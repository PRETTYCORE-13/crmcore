defmodule PrettycoreWeb.ClientesExcelController do
  use PrettycoreWeb, :controller

  alias Prettycore.Clientes.Excel, as: ClientesExcel

  @doc """
  Descarga un archivo Excel con todos los clientes y columnas seleccionadas
  """
  def download(conn, params) do
    # Obtener parámetros de filtro con valores por defecto
    sysudn = get_param_or_default(params["sysudn"], "100")
    ruta_desde = get_param_or_default(params["ruta_desde"], "001")
    ruta_hasta = get_param_or_default(params["ruta_hasta"], "99999")

    # Obtener el token de la sesión para autenticación con la API
    frog_token = get_session(conn, :frog_token)

    # Parsear columnas visibles desde los params
    visible_columns = parse_visible_columns(params)

    # Generar el archivo Excel con el token
    excel_binary = ClientesExcel.generar_excel(
      sysudn,
      ruta_desde,
      ruta_hasta,
      visible_columns,
      frog_token
    )

    # Generar nombre de archivo con timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    filename = "clientes_#{timestamp}.xlsx"

    # Enviar el archivo como descarga con headers correctos para Excel
    conn
    |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "utf-8")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> put_resp_header("content-transfer-encoding", "binary")
    |> send_resp(200, excel_binary)
  end

  # Parsea las columnas visibles desde los params de la URL
  defp parse_visible_columns(params) do
    visible_cols = case Map.get(params, "visible_columns") do
      # Si viene como mapa anidado (Phoenix ya lo parseó)
      %{} = nested_map ->
        nested_map
        |> Enum.map(fn {key, value} ->
          {key, value == "true" || value == true}
        end)
        |> Enum.into(%{})

      # Si viene en formato plano con keys "visible_columns[...]"
      _ ->
        params
        |> Enum.filter(fn {key, _value} -> String.starts_with?(to_string(key), "visible_columns[") end)
        |> Enum.map(fn {key, value} ->
          column_name = String.replace(to_string(key), ~r/visible_columns\[(.*)\]/, "\\1")
          {column_name, value == "true"}
        end)
        |> Enum.into(%{})
    end

    IO.inspect(visible_cols, label: "📊 Columnas visibles parseadas")
    visible_cols
  end

  # Helper para obtener parámetro o usar valor por defecto
  defp get_param_or_default(nil, default), do: default
  defp get_param_or_default("", default), do: default
  defp get_param_or_default(value, _default) when is_binary(value), do: value
end
