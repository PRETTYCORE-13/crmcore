defmodule Prettycore.Api.Cache do
  @moduledoc """
  Cache ETS simple para respuestas de la API REST.
  Los datos de catálogos no cambian frecuentemente, así que se cachean
  por un TTL configurable (default 5 minutos).
  """
  use GenServer

  @table :api_cache
  @default_ttl :timer.minutes(5)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Obtiene un valor del cache o ejecuta la función y lo guarda.
  """
  def fetch(key, fun) do
    case get(key) do
      {:ok, value} ->
        value

      :miss ->
        result = fun.()
        put(key, result)
        result
    end
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value, expires_at}] ->
        if System.monotonic_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :ets.delete(@table, key)
          :miss
        end

      [] ->
        :miss
    end
  rescue
    ArgumentError -> :miss
  end

  def put(key, value, ttl \\ @default_ttl) do
    expires_at = System.monotonic_time(:millisecond) + ttl
    :ets.insert(@table, {key, value, expires_at})
    :ok
  rescue
    ArgumentError -> :ok
  end

  def clear do
    :ets.delete_all_objects(@table)
    :ok
  rescue
    ArgumentError -> :ok
  end

  # GenServer callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
