defmodule Latin1String do
  @moduledoc """
  Custom Ecto type that automatically converts Latin-1/CP1252 encoded strings to UTF-8.

  This is useful when SQL Server returns text in Latin-1 encoding instead of UTF-8.
  The type automatically converts the encoding when loading from the database.

  ## Usage

      schema "my_table" do
        field :description, Latin1String, source: :DESCRIPTION
      end
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(value) when is_binary(value), do: {:ok, convert_to_utf8(value)}
  def cast(nil), do: {:ok, nil}
  def cast(_), do: :error

  @impl true
  def load(value) when is_binary(value) do
    {:ok, convert_to_utf8(value)}
  end

  def load(nil), do: {:ok, nil}
  def load(_), do: :error

  @impl true
  def dump(value) when is_binary(value), do: {:ok, value}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error

  # Convert Latin-1 to UTF-8
  defp convert_to_utf8(value) when is_binary(value) do
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

  defp convert_to_utf8(value), do: value
end
