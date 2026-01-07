defmodule Prettycore.WorkordersTest do
  use ExUnit.Case, async: false

  alias Prettycore.Workorders
  alias Prettycore.Workorders.WorkorderEnc

  describe "list_enc/0" do
    test "returns a list of WorkorderEnc structs" do
      result = Workorders.list_enc()

      # Verify it returns a list
      assert is_list(result)

      # If there are results, verify the structure
      if length(result) > 0 do
        first_workorder = List.first(result)

        # Verify it's a WorkorderEnc struct
        assert %WorkorderEnc{} = first_workorder

        # Verify it has the expected fields
        assert Map.has_key?(first_workorder, :sysudn)
        assert Map.has_key?(first_workorder, :systra)
        assert Map.has_key?(first_workorder, :serie)
        assert Map.has_key?(first_workorder, :folio)
        assert Map.has_key?(first_workorder, :referencia)
        assert Map.has_key?(first_workorder, :estado)
        assert Map.has_key?(first_workorder, :descripcion)
        assert Map.has_key?(first_workorder, :fecha)
        assert Map.has_key?(first_workorder, :usuario)
      end
    end

    test "returns workorders with valid data types" do
      result = Workorders.list_enc()

      # If there are results, verify the data types
      if length(result) > 0 do
        first_workorder = List.first(result)

        # Verify data types
        assert is_binary(first_workorder.sysudn) or is_nil(first_workorder.sysudn)
        assert is_binary(first_workorder.systra) or is_nil(first_workorder.systra)
        assert is_binary(first_workorder.serie) or is_nil(first_workorder.serie)
        assert is_integer(first_workorder.folio) or is_nil(first_workorder.folio)
        assert is_binary(first_workorder.referencia) or is_nil(first_workorder.referencia)
        assert is_integer(first_workorder.estado) or is_nil(first_workorder.estado)
        assert is_binary(first_workorder.descripcion) or is_nil(first_workorder.descripcion)
        assert is_binary(first_workorder.usuario) or is_nil(first_workorder.usuario)

        # Fecha should be NaiveDateTime or nil
        assert is_nil(first_workorder.fecha) or
                 match?(%NaiveDateTime{}, first_workorder.fecha)
      end
    end

    test "successfully queries the database without errors" do
      # This test verifies that the function executes without raising an error
      result =
        try do
          Workorders.list_enc()
          {:ok, :success}
        rescue
          _error -> {:error, :failed}
        end

      assert {:ok, _} = result
    end
  end

  describe "list_enc_filtered/1" do
    test "returns all workorders when no filters are provided" do
      result = Workorders.list_enc_filtered()

      assert is_list(result)
    end

    test "returns all workorders when filters is empty map" do
      result = Workorders.list_enc_filtered(%{})

      assert is_list(result)
    end

    test "filters by estado 'por_aceptar' (estado == 100)" do
      result = Workorders.list_enc_filtered(%{estado: "por_aceptar"})

      assert is_list(result)

      # Verify all returned workorders have estado == 100
      if length(result) > 0 do
        Enum.each(result, fn workorder ->
          assert workorder.estado == 100
        end)
      end
    end

    test "filters by specific estado integer" do
      result = Workorders.list_enc_filtered(%{estado: 100})

      assert is_list(result)

      if length(result) > 0 do
        Enum.each(result, fn workorder ->
          assert workorder.estado == 100
        end)
      end
    end

    test "filters by estado string number" do
      result = Workorders.list_enc_filtered(%{estado: "100"})

      assert is_list(result)

      if length(result) > 0 do
        Enum.each(result, fn workorder ->
          assert workorder.estado == 100
        end)
      end
    end

    test "returns all workorders when estado is 'todas'" do
      result_todas = Workorders.list_enc_filtered(%{estado: "todas"})
      result_all = Workorders.list_enc_filtered()

      assert is_list(result_todas)
      # Should return same count as no filter
      assert length(result_todas) == length(result_all)
    end

    test "filters by sysudn" do
      # First get any workorder to get a valid sysudn
      all_workorders = Workorders.list_enc_filtered()

      if length(all_workorders) > 0 do
        sample_sysudn = List.first(all_workorders).sysudn

        result = Workorders.list_enc_filtered(%{sysudn: sample_sysudn})

        assert is_list(result)

        if length(result) > 0 do
          Enum.each(result, fn workorder ->
            assert workorder.sysudn == sample_sysudn
          end)
        end
      end
    end

    test "filters by usuario" do
      # First get any workorder to get a valid usuario
      all_workorders = Workorders.list_enc_filtered()

      if length(all_workorders) > 0 do
        sample_usuario = List.first(all_workorders).usuario

        if sample_usuario do
          result = Workorders.list_enc_filtered(%{usuario: sample_usuario})

          assert is_list(result)

          if length(result) > 0 do
            Enum.each(result, fn workorder ->
              assert workorder.usuario == sample_usuario
            end)
          end
        end
      end
    end

    test "filters by fecha_desde" do
      fecha_desde = "2025-01-01"

      result = Workorders.list_enc_filtered(%{fecha_desde: fecha_desde})

      assert is_list(result)

      if length(result) > 0 do
        {:ok, cutoff_date} = Date.from_iso8601(fecha_desde)
        cutoff_naive = NaiveDateTime.new!(cutoff_date, ~T[00:00:00])

        Enum.each(result, fn workorder ->
          if workorder.fecha do
            assert NaiveDateTime.compare(workorder.fecha, cutoff_naive) in [:gt, :eq]
          end
        end)
      end
    end

    test "filters by fecha_hasta" do
      fecha_hasta = "2025-12-31"

      result = Workorders.list_enc_filtered(%{fecha_hasta: fecha_hasta})

      assert is_list(result)

      if length(result) > 0 do
        {:ok, cutoff_date} = Date.from_iso8601(fecha_hasta)
        cutoff_naive = NaiveDateTime.new!(cutoff_date, ~T[23:59:59])

        Enum.each(result, fn workorder ->
          if workorder.fecha do
            assert NaiveDateTime.compare(workorder.fecha, cutoff_naive) in [:lt, :eq]
          end
        end)
      end
    end

    test "filters by fecha_desde and fecha_hasta range" do
      fecha_desde = "2025-01-01"
      fecha_hasta = "2025-12-31"

      result =
        Workorders.list_enc_filtered(%{
          fecha_desde: fecha_desde,
          fecha_hasta: fecha_hasta
        })

      assert is_list(result)

      if length(result) > 0 do
        {:ok, desde_date} = Date.from_iso8601(fecha_desde)
        {:ok, hasta_date} = Date.from_iso8601(fecha_hasta)
        desde_naive = NaiveDateTime.new!(desde_date, ~T[00:00:00])
        hasta_naive = NaiveDateTime.new!(hasta_date, ~T[23:59:59])

        Enum.each(result, fn workorder ->
          if workorder.fecha do
            assert NaiveDateTime.compare(workorder.fecha, desde_naive) in [:gt, :eq]
            assert NaiveDateTime.compare(workorder.fecha, hasta_naive) in [:lt, :eq]
          end
        end)
      end
    end

    test "filters by multiple criteria" do
      all_workorders = Workorders.list_enc_filtered()

      if length(all_workorders) > 0 do
        sample = List.first(all_workorders)

        result =
          Workorders.list_enc_filtered(%{
            estado: sample.estado,
            sysudn: sample.sysudn
          })

        assert is_list(result)

        if length(result) > 0 do
          Enum.each(result, fn workorder ->
            assert workorder.estado == sample.estado
            assert workorder.sysudn == sample.sysudn
          end)
        end
      end
    end

    test "ignores empty string filters" do
      result_with_empty =
        Workorders.list_enc_filtered(%{
          estado: "",
          sysudn: "",
          usuario: ""
        })

      result_no_filter = Workorders.list_enc_filtered()

      assert is_list(result_with_empty)
      # Empty strings should be ignored, so results should match no filter
      assert length(result_with_empty) == length(result_no_filter)
    end

    test "ignores nil filters" do
      result_with_nil =
        Workorders.list_enc_filtered(%{
          estado: nil,
          sysudn: nil,
          usuario: nil
        })

      result_no_filter = Workorders.list_enc_filtered()

      assert is_list(result_with_nil)
      # Nils should be ignored, so results should match no filter
      assert length(result_with_nil) == length(result_no_filter)
    end

    test "handles invalid date formats gracefully" do
      result =
        Workorders.list_enc_filtered(%{
          fecha_desde: "invalid-date",
          fecha_hasta: "not-a-date"
        })

      # Should not crash, just ignore invalid dates
      assert is_list(result)
    end

    test "returns WorkorderEnc structs with preloaded associations" do
      result = Workorders.list_enc_filtered()

      if length(result) > 0 do
        first_workorder = List.first(result)

        assert %WorkorderEnc{} = first_workorder

        # Verify tipo association is loaded (not %Ecto.Association.NotLoaded{})
        assert Map.has_key?(first_workorder, :tipo)
        refute match?(%Ecto.Association.NotLoaded{}, first_workorder.tipo)
      end
    end

    test "successfully queries the database without errors" do
      result =
        try do
          Workorders.list_enc_filtered(%{estado: "por_aceptar"})
          {:ok, :success}
        rescue
          _error -> {:error, :failed}
        end

      assert {:ok, _} = result
    end
  end
end
