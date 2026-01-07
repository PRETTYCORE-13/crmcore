defmodule Prettycore.EncodingUtils do
  @moduledoc """
  Utilities for handling text encoding issues from SQL Server.

  SQL Server may return text in Latin-1/CP1252 encoding instead of UTF-8.
  This module provides functions to convert those strings to valid UTF-8.
  """

  @doc """
  Converts a Latin-1 (ISO-8859-1) encoded string to UTF-8.
  Returns the original value if it's already valid UTF-8 or not a string.
  """
  def to_utf8(value) when is_binary(value) do
    if String.valid?(value) do
      # Already valid UTF-8
      value
    else
      # Try to convert from Latin-1 to UTF-8
      case :unicode.characters_to_binary(value, :latin1, :utf8) do
        utf8_string when is_binary(utf8_string) -> utf8_string
        {:error, _, _} -> value
        {:incomplete, _, _} -> value
      end
    end
  end

  def to_utf8(value), do: value

  @doc """
  Recursively converts all string values in a map or list from Latin-1 to UTF-8.
  """
  def convert_map_to_utf8(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, convert_to_utf8(v)} end)
  end

  def convert_map_to_utf8(value), do: convert_to_utf8(value)

  defp convert_to_utf8(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, convert_to_utf8(v)} end)
  end

  defp convert_to_utf8(list) when is_list(list) do
    Enum.map(list, &convert_to_utf8/1)
  end

  defp convert_to_utf8(value) when is_binary(value) do
    to_utf8(value)
  end

  defp convert_to_utf8(value), do: value
end
