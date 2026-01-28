defmodule Prettycore.CfgMetodoPago do
  @moduledoc """
  Contexto para consultar métodos de pago desde CFG_METODOPAGO
  """
  import Ecto.Query

  @doc """
  Lista todos los métodos de pago ordenados por código
  """
  def listar_metodos_pago do
    query = """
    SELECT
      CFGMTP_CODIGO_K AS codigo,
      CFGMTP_DESCRIPCION AS descripcion
    FROM
      CFG_METODOPAGO
    ORDER BY CFGMTP_CODIGO_K
    """

    case Repo.query(query, []) do
      {:ok, %{rows: rows, columns: columns}} ->
        rows
        |> Enum.map(fn row ->
          columns
          |> Enum.zip(row)
          |> Map.new()
        end)

      {:error, _} ->
        []
    end
  end

  @doc """
  Obtiene un método de pago por su código
  """
  def obtener_por_codigo(codigo) do
    query = """
    SELECT
      CFGMTP_CODIGO_K AS codigo,
      CFGMTP_DESCRIPCION AS descripcion
    FROM
      CFG_METODOPAGO
    WHERE CFGMTP_CODIGO_K = ?
    """

    case Repo.query(query, [codigo]) do
      {:ok, %{rows: [row], columns: columns}} ->
        {:ok,
         columns
         |> Enum.zip(row)
         |> Map.new()}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
