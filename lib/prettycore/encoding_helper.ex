defmodule Prettycore.EncodingHelper do
  @moduledoc """
  Helpers for converting SQL Server Latin-1/CP1252 strings to UTF-8.

  ## Problem

  SQL Server VARCHAR columns return data in CP1252 (Latin-1) encoding, but Phoenix
  and Jason require UTF-8. This causes `Jason.EncodeError: invalid byte` errors when
  LiveView tries to serialize assigns containing Spanish characters like "ó", "ñ", "á".

  ## Solution

  This module provides conversion utilities to transform Latin-1 bytes to UTF-8.

  **Long-term**: Migrate VARCHAR columns to NVARCHAR in SQL Server.
  **Short-term**: Use these helpers to convert data after querying.

  ## Examples

      # Convert a single string
      iex> EncodingHelper.latin1_to_utf8(<<74, 111, 115, 233>>)  # Latin-1 "José"
      "José"  # UTF-8

      # Convert catalog tuples
      iex> EncodingHelper.convert_catalog_list([{<<77, 233, 120, 105, 99, 111>>, "15"}])
      [{"México", "15"}]

      # Convert a map (for API responses)
      iex> EncodingHelper.convert_map(%{"nombre" => <<74, 111, 115, 233>>})
      %{"nombre" => "José"}
  """

  require Logger

  @doc """
  Converts a Latin-1 (CP1252) binary to UTF-8.

  Handles the following cases:
  - Latin-1 encoded strings → converts to UTF-8
  - Already UTF-8 strings → returns as-is
  - nil or empty string → returns as-is
  - Non-binary values → returns as-is

  ## Examples

      iex> latin1_to_utf8(<<74, 111, 115, 233>>)  # Latin-1 "José"
      "José"

      iex> latin1_to_utf8("México")  # Already UTF-8
      "México"

      iex> latin1_to_utf8(nil)
      nil

      iex> latin1_to_utf8("")
      ""

      iex> latin1_to_utf8(123)
      123
  """
  @spec latin1_to_utf8(binary() | nil | any()) :: binary() | nil | any()
  def latin1_to_utf8(nil), do: nil
  def latin1_to_utf8(""), do: ""

  def latin1_to_utf8(binary) when is_binary(binary) do
    # Try to convert from Latin-1 to UTF-8
    case :unicode.characters_to_binary(binary, :latin1, :utf8) do
      utf8_string when is_binary(utf8_string) ->
        # Check if conversion actually changed anything
        if utf8_string == binary do
          # String was already UTF-8 or ASCII
          binary
        else
          # Successfully converted from Latin-1 to UTF-8
          utf8_string
        end

      {:error, good, bad} ->
        # Conversion failed - string might be mixed encoding or already UTF-8
        Logger.debug("""
        EncodingHelper: Failed to convert string from Latin-1 to UTF-8
        Good part: #{inspect(good)}
        Bad part: #{inspect(bad)}
        Returning original string.
        """)
        binary

      {:incomplete, good, bad} ->
        # Incomplete sequence
        Logger.debug("""
        EncodingHelper: Incomplete Latin-1 sequence
        Good part: #{inspect(good)}
        Bad part: #{inspect(bad)}
        Returning original string.
        """)
        binary
    end
  end

  def latin1_to_utf8(other), do: other

  @doc """
  Converts a list of tuples containing Latin-1 strings to UTF-8.

  Useful for catalog functions that return `{name, code}` tuples.

  ## Examples

      iex> convert_catalog_list([{"México", "1"}, {"Bogotá", "2"}])
      [{"México", "1"}, {"Bogotá", "2"}]

      iex> convert_catalog_list([{<<77, 233, 120>>, "1"}])  # Latin-1 "Méx"
      [{"Méx", "1"}]

      iex> convert_catalog_list([])
      []
  """
  @spec convert_catalog_list(list()) :: list()
  def convert_catalog_list([]), do: []

  def convert_catalog_list(list) when is_list(list) do
    Enum.map(list, fn
      {name, code} when is_binary(name) ->
        {latin1_to_utf8(name), code}

      {name, code, extra} when is_binary(name) ->
        {latin1_to_utf8(name), code, extra}

      tuple when is_tuple(tuple) ->
        tuple
        |> Tuple.to_list()
        |> Enum.map(&latin1_to_utf8/1)
        |> List.to_tuple()

      other ->
        other
    end)
  end

  @doc """
  Converts a map's string values from Latin-1 to UTF-8.

  Recursively processes nested maps and lists. Useful for converting
  entire API response payloads or Ecto query results.

  ## Examples

      iex> convert_map(%{"nombre" => "José", "edad" => 30})
      %{"nombre" => "José", "edad" => 30}

      iex> convert_map(%{"cliente" => %{"nombre" => "José"}})
      %{"cliente" => %{"nombre" => "José"}}

      iex> convert_map(%{"nombres" => ["José", "María"]})
      %{"nombres" => ["José", "María"]}
  """
  @spec convert_map(map()) :: map()
  def convert_map(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {key, convert_value(value)}
    end)
  end

  @doc """
  Converts a list of maps from Latin-1 to UTF-8.

  Useful for converting database query results that return lists of maps.

  ## Examples

      iex> convert_list_of_maps([
      ...>   %{"nombre" => "José", "ciudad" => "México"},
      ...>   %{"nombre" => "María", "ciudad" => "Bogotá"}
      ...> ])
      [
        %{"nombre" => "José", "ciudad" => "México"},
        %{"nombre" => "María", "ciudad" => "Bogotá"}
      ]
  """
  @spec convert_list_of_maps(list()) :: list()
  def convert_list_of_maps(list) when is_list(list) do
    Enum.map(list, fn
      map when is_map(map) -> convert_map(map)
      other -> other
    end)
  end

  # Private helper to recursively convert values
  defp convert_value(value) when is_binary(value), do: latin1_to_utf8(value)
  defp convert_value(value) when is_map(value), do: convert_map(value)
  defp convert_value(value) when is_list(value), do: Enum.map(value, &convert_value/1)
  defp convert_value(value), do: value

  @doc """
  Validates that a string is valid UTF-8.

  Returns `{:ok, string}` if valid, `{:error, reason}` if invalid.

  ## Examples

      iex> validate_utf8("José")
      {:ok, "José"}

      iex> validate_utf8(<<233>>)  # Invalid UTF-8
      {:error, :invalid_utf8}
  """
  @spec validate_utf8(binary()) :: {:ok, binary()} | {:error, :invalid_utf8}
  def validate_utf8(binary) when is_binary(binary) do
    if String.valid?(binary) do
      {:ok, binary}
    else
      {:error, :invalid_utf8}
    end
  end

  @doc """
  Checks if a binary contains Latin-1 encoded data (vs UTF-8).

  Returns `true` if the binary appears to be Latin-1 encoded.

  ## Examples

      iex> is_latin1?(<<233>>)  # Single byte 'é' in Latin-1
      true

      iex> is_latin1?("José")  # UTF-8 encoded
      false
  """
  @spec is_latin1?(binary()) :: boolean()
  def is_latin1?(binary) when is_binary(binary) do
    # If it's valid UTF-8, it's not Latin-1
    if String.valid?(binary) do
      false
    else
      # Try to convert from Latin-1 to UTF-8
      case :unicode.characters_to_binary(binary, :latin1, :utf8) do
        utf8 when is_binary(utf8) ->
          # Conversion succeeded and result is valid UTF-8
          String.valid?(utf8)

        _ ->
          false
      end
    end
  end

  @doc """
  Safely converts a value to UTF-8, with fallback to empty string on error.

  Useful when you want to ensure no crashes occur during conversion.

  ## Examples

      iex> safe_convert("José")
      "José"

      iex> safe_convert(<<233>>)
      "é"

      iex> safe_convert(nil)
      ""
  """
  @spec safe_convert(any()) :: binary()
  def safe_convert(nil), do: ""
  def safe_convert(""), do: ""

  def safe_convert(binary) when is_binary(binary) do
    latin1_to_utf8(binary)
  rescue
    _ -> ""
  end

  def safe_convert(_), do: ""
end
