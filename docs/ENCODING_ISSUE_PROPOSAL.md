# SQL Server VARCHAR Encoding Issue - Proposal

## Problem Statement

### The Error
```elixir
** (Jason.EncodeError) invalid byte 0xF3 in <<...>>
```

This error occurs when LiveView attempts to serialize assigns containing strings with Latin-1 characters (like "ó", "ñ", "á") that come from SQL Server VARCHAR columns.

### Root Cause

The application is experiencing encoding mismatches due to the following chain:

1. **SQL Server VARCHAR columns** store data in **CP1252/Latin-1** encoding
2. **The `:tds` driver** retrieves this data as **raw Latin-1 bytes** without conversion
3. **Phoenix LiveView** and **Jason** expect **all strings to be valid UTF-8**
4. When Latin-1 bytes are passed to LiveView assigns, **Jason crashes** trying to encode invalid UTF-8

### Technical Details

```
SQL Server VARCHAR → CP1252/Latin-1 bytes → :tds driver (no conversion) →
Elixir strings (Latin-1 bytes) → LiveView assigns → Jason.encode! → CRASH ❌
```

Example of the problem:
```elixir
# From SQL Server VARCHAR column containing "José"
# Returns: <<74, 111, 115, 233>> (Latin-1 for "José" where 233 = é)
# Expected UTF-8: <<74, 111, 115, 195, 169>> (UTF-8 for "José" where 195, 169 = é)

# When passed to Jason:
Jason.encode!(%{name: "Jos\xE9"})  # Latin-1 byte 0xE9
** (Jason.EncodeError) invalid byte 0xE9 in <<"Jos", 233>>
```

### Affected Areas

1. **`lib/prettycore/catalogos.ex`** - All catalog functions returning names/descriptions
2. **`lib/prettycore/clientes_api.ex`** - Client data with names, addresses
3. **LiveView assigns** - Any data passed to templates containing Latin-1 characters
4. **JSON API responses** - External API calls returning client/catalog data

---

## Long-Term Solution (Recommended)

### Migrate VARCHAR to NVARCHAR

**Why NVARCHAR?**
- NVARCHAR stores data as **UCS-2/UTF-16** in SQL Server
- The `:tds` driver **automatically converts** NVARCHAR to UTF-8
- This is the **correct** and **permanent** solution

**Migration Strategy:**

```sql
-- Example migration for MAP_ESTADO table
ALTER TABLE MAP_ESTADO
ALTER COLUMN MAPEDO_NOMBRE NVARCHAR(100);

-- Example migration for CTE_CLIENTE table
ALTER TABLE CTE_CLIENTE
ALTER COLUMN CTECLI_RAZONSOCIAL NVARCHAR(200);

ALTER TABLE CTE_CLIENTE
ALTER COLUMN CTECLI_DENCOMERCIA NVARCHAR(200);
```

**Rollout Plan:**

1. **Phase 1** - Identify all VARCHAR columns with non-ASCII data:
   ```sql
   SELECT
       TABLE_NAME,
       COLUMN_NAME,
       CHARACTER_MAXIMUM_LENGTH
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE DATA_TYPE = 'varchar'
     AND TABLE_SCHEMA = 'dbo'
   ORDER BY TABLE_NAME, COLUMN_NAME;
   ```

2. **Phase 2** - Migrate high-priority tables first:
   - MAP_ESTADO, MAP_MUNICIPIO, MAP_LOCALIDAD (geography data)
   - CTE_CLIENTE, CTE_DIRECCION (client data)
   - Catalog tables (CFG_*, CTE_*, MAP_*)

3. **Phase 3** - Test and validate data integrity

4. **Phase 4** - Migrate remaining tables

**Estimated Impact:**
- Storage: NVARCHAR uses 2 bytes per character vs 1 byte for VARCHAR
- For a table with 1M rows and 50-char column: ~50MB additional storage
- Performance: Negligible impact on modern hardware
- **Benefit: Eliminates encoding issues permanently** ✅

---

## Short-Term Mitigations

While planning the VARCHAR→NVARCHAR migration, use these immediate fixes:

### Option 1: Query-Level Conversion (Recommended for Quick Fix)

Modify queries to convert VARCHAR to NVARCHAR at retrieval:

```elixir
# Before (returns Latin-1):
def listar_estados do
  query = """
  SELECT MAPEDO_NOMBRE, MAPEDO_CODIGO
  FROM MAP_ESTADO
  ORDER BY MAPEDO_NOMBRE
  """

  case Repo.query(query, []) do
    {:ok, result} ->
      Enum.map(result.rows, fn [nombre, codigo] ->
        {nombre, codigo}  # nombre is Latin-1 ❌
      end)
    {:error, _} -> []
  end
end

# After (returns UTF-8):
def listar_estados do
  query = """
  SELECT
    CONVERT(NVARCHAR(100), MAPEDO_NOMBRE) AS MAPEDO_NOMBRE,
    MAPEDO_CODIGO
  FROM MAP_ESTADO
  ORDER BY MAPEDO_NOMBRE
  """

  case Repo.query(query, []) do
    {:ok, result} ->
      Enum.map(result.rows, fn [nombre, codigo] ->
        {nombre, codigo}  # nombre is UTF-8 ✅
      end)
    {:error, _} -> []
  end
end
```

**Pros:**
- ✅ Quick to implement
- ✅ No code changes outside query
- ✅ Works immediately

**Cons:**
- ❌ Must update every query manually
- ❌ Conversion overhead on every query
- ❌ Easy to miss a query

### Option 2: Application-Level Conversion Helper

Create a helper module to convert Latin-1 to UTF-8:

```elixir
# lib/prettycore/encoding_helper.ex
defmodule Prettycore.EncodingHelper do
  @moduledoc """
  Helpers for converting SQL Server Latin-1/CP1252 strings to UTF-8.

  SQL Server VARCHAR columns return data in CP1252 encoding, but Phoenix
  and Jason require UTF-8. This module provides conversion utilities.
  """

  @doc """
  Converts a Latin-1 (CP1252) binary to UTF-8.

  ## Examples

      iex> latin1_to_utf8("Jos\xE9")  # Latin-1 "José"
      "José"  # UTF-8 "José"

      iex> latin1_to_utf8("México")  # Already UTF-8
      "México"
  """
  def latin1_to_utf8(nil), do: nil
  def latin1_to_utf8(""), do: ""

  def latin1_to_utf8(binary) when is_binary(binary) do
    case :unicode.characters_to_binary(binary, :latin1, :utf8) do
      utf8_string when is_binary(utf8_string) ->
        utf8_string

      {:error, _good, _bad} ->
        # Already UTF-8 or mixed encoding, return as-is
        binary

      {:incomplete, _good, _bad} ->
        # Incomplete sequence, return as-is
        binary
    end
  end

  def latin1_to_utf8(other), do: other

  @doc """
  Converts a list of tuples containing Latin-1 strings to UTF-8.

  Useful for catalog functions that return {name, code} tuples.

  ## Examples

      iex> convert_catalog_list([{"México", "1"}, {"Bogotá", "2"}])
      [{"México", "1"}, {"Bogotá", "2"}]  # All UTF-8
  """
  def convert_catalog_list(list) when is_list(list) do
    Enum.map(list, fn
      {name, code} ->
        {latin1_to_utf8(name), code}

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

  Recursively processes nested maps and lists.
  """
  def convert_map(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {key, convert_value(value)}
    end)
  end

  defp convert_value(value) when is_binary(value), do: latin1_to_utf8(value)
  defp convert_value(value) when is_map(value), do: convert_map(value)
  defp convert_value(value) when is_list(value), do: Enum.map(value, &convert_value/1)
  defp convert_value(value), do: value
end
```

**Usage in catalogos.ex:**

```elixir
defmodule Prettycore.Catalogos do
  alias Prettycore.Repo
  alias Prettycore.EncodingHelper

  def listar_estados do
    query = """
    SELECT MAPEDO_NOMBRE, MAPEDO_CODIGO
    FROM MAP_ESTADO
    ORDER BY MAPEDO_NOMBRE
    """

    case Repo.query(query, []) do
      {:ok, result} ->
        result.rows
        |> Enum.map(fn [nombre, codigo] -> {nombre, codigo} end)
        |> EncodingHelper.convert_catalog_list()  # Convert Latin-1 to UTF-8 ✅

      {:error, _} -> []
    end
  end

  def listar_municipios(estado_codigo) do
    query = """
    SELECT MAPMUN_NOMBRE, MAPMUN_CODIGO
    FROM MAP_MUNICIPIO
    WHERE MAPEDO_CODIGO_K = @estado_codigo
    ORDER BY MAPMUN_NOMBRE
    """

    case Repo.query(query, [estado_codigo]) do
      {:ok, result} ->
        result.rows
        |> Enum.map(fn [nombre, codigo] -> {nombre, codigo} end)
        |> EncodingHelper.convert_catalog_list()  # Convert Latin-1 to UTF-8 ✅

      {:error, _} -> []
    end
  end
end
```

**Pros:**
- ✅ Centralized conversion logic
- ✅ Easy to apply to existing code
- ✅ Can be removed after VARCHAR→NVARCHAR migration
- ✅ Handles mixed encodings gracefully

**Cons:**
- ❌ Requires updating all affected functions
- ❌ Runtime conversion overhead
- ❌ Temporary solution

### Option 3: Ecto Custom Type (For Ecto Schemas)

If using Ecto schemas with SQL Server:

```elixir
# lib/prettycore/ecto_types/latin1_string.ex
defmodule Prettycore.EctoTypes.Latin1String do
  @moduledoc """
  Custom Ecto type that converts Latin-1 strings from SQL Server VARCHAR
  columns to UTF-8 when loading from database.
  """

  use Ecto.Type

  def type, do: :string

  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_), do: :error

  def load(value) when is_binary(value) do
    case :unicode.characters_to_binary(value, :latin1, :utf8) do
      utf8 when is_binary(utf8) -> {:ok, utf8}
      _ -> {:ok, value}  # Return as-is if conversion fails
    end
  end

  def dump(value) when is_binary(value), do: {:ok, value}
  def dump(_), do: :error
end
```

**Usage in schema:**

```elixir
defmodule Prettycore.Cliente do
  use Ecto.Schema

  alias Prettycore.EctoTypes.Latin1String

  schema "CTE_CLIENTE" do
    field :ctecli_razonsocial, Latin1String  # Will auto-convert ✅
    field :ctecli_dencomercia, Latin1String
    # ... other fields
  end
end
```

---

## Recommended Implementation Plan

### Immediate (This Week)
1. ✅ Create `EncodingHelper` module
2. ✅ Update `Catalogos` module functions to use `convert_catalog_list/1`
3. ✅ Update `ClientesApi` to convert client data
4. ✅ Test LiveView pages with Spanish characters
5. ✅ Monitor error logs for encoding issues

### Short-Term (This Month)
1. Audit all queries returning VARCHAR data
2. Add encoding conversion to all affected functions
3. Create tests with Spanish/Latin characters
4. Document encoding requirements in developer guide

### Long-Term (Next Quarter)
1. Create VARCHAR→NVARCHAR migration scripts
2. Test migrations in development environment
3. Schedule production migration window
4. Execute migration in phases
5. Remove `EncodingHelper` after migration complete

---

## Testing Strategy

### Test Cases with Latin-1 Characters

```elixir
# test/prettycore/encoding_test.exs
defmodule Prettycore.EncodingTest do
  use ExUnit.Case
  alias Prettycore.EncodingHelper

  describe "latin1_to_utf8/1" do
    test "converts common Spanish characters" do
      # Latin-1 bytes for "José"
      latin1_jose = <<74, 111, 115, 233>>
      assert EncodingHelper.latin1_to_utf8(latin1_jose) == "José"

      # Latin-1 bytes for "México"
      latin1_mexico = <<77, 233, 120, 105, 99, 111>>
      assert EncodingHelper.latin1_to_utf8(latin1_mexico) == "México"

      # Latin-1 bytes for "Bogotá"
      latin1_bogota = <<66, 111, 103, 111, 116, 225>>
      assert EncodingHelper.latin1_to_utf8(latin1_bogota) == "Bogotá"
    end

    test "handles already UTF-8 strings" do
      utf8_string = "México"
      assert EncodingHelper.latin1_to_utf8(utf8_string) == "México"
    end

    test "handles nil and empty string" do
      assert EncodingHelper.latin1_to_utf8(nil) == nil
      assert EncodingHelper.latin1_to_utf8("") == ""
    end
  end

  describe "LiveView integration" do
    test "can encode catalog data with Spanish characters" do
      # Simulate data from SQL Server
      estados = [
        {"México", "15"},
        {"Jalisco", "14"},
        {"Nuevo León", "19"}
      ]

      converted = EncodingHelper.convert_catalog_list(estados)

      # Should not raise Jason.EncodeError
      assert {:ok, _json} = Jason.encode(%{estados: converted})
    end
  end
end
```

### Integration Test

```elixir
# test/prettycore_web/live/cliente_form_live_encoding_test.exs
defmodule PrettycoreWeb.ClienteFormLiveEncodingTest do
  use PrettycoreWeb.LiveCase

  @tag :authenticated
  test "renders estados with Spanish characters without crashing", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

    # Should contain Estado de México without errors
    assert html =~ "México"

    # Should be able to select estado with Spanish name
    result = view
    |> form("form", cliente_form: %{
      "direcciones" => %{
        "0" => %{
          "mapedo_codigo_k" => "15"  # Estado de México
        }
      }
    })
    |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

    # Should load municipios without Jason.EncodeError
    assert result =~ "Acambay"
    assert result =~ "Acolman"
  end
end
```

---

## Monitoring and Validation

### After Implementing Mitigations

```elixir
# Add to application monitoring
def check_encoding_issues do
  # Query for VARCHAR columns that might have issues
  query = """
  SELECT TOP 100
    TABLE_NAME,
    COLUMN_NAME,
    (SELECT TOP 1 #{column_name}
     FROM #{table_name}
     WHERE #{column_name} LIKE '%[á-ú]%'
        OR #{column_name} LIKE '%[Á-Ú]%'
        OR #{column_name} LIKE '%ñ%'
        OR #{column_name} LIKE '%Ñ%')
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE DATA_TYPE = 'varchar'
  ```

  # Test encoding for each column
  # Flag any that fail UTF-8 validation
end
```

---

## Summary

| Solution | Effort | Timeline | Permanence |
|----------|--------|----------|------------|
| **Query-level CONVERT()** | Low | Immediate | Temporary |
| **EncodingHelper** | Medium | 1-2 days | Temporary |
| **Custom Ecto Type** | Medium | 2-3 days | Temporary |
| **VARCHAR→NVARCHAR Migration** | High | 1-2 months | **Permanent** ✅ |

### Recommendation

1. **This week**: Implement `EncodingHelper` for immediate relief
2. **This month**: Plan and test VARCHAR→NVARCHAR migration
3. **Next quarter**: Execute migration and remove helper

The `EncodingHelper` approach provides the best balance of:
- Quick implementation
- Centralized logic
- Easy to remove after migration
- Handles edge cases gracefully

Once VARCHAR columns are migrated to NVARCHAR, the `:tds` driver will handle UTF-8 conversion automatically, and all encoding helpers can be safely removed.
