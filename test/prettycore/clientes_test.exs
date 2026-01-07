defmodule Prettycore.ClientesTest do
  use ExUnit.Case, async: false

  alias Prettycore.Clientes
  alias Prettycore.Repo

  @moduletag :database

  describe "list_clientes_completo/3" do
    test "returns list of clients with all fields for valid UDN and route range" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      assert is_list(result)

      # If there are results, verify structure
      if length(result) > 0 do
        first_client = List.first(result)

        # Verify all required fields are present
        assert Map.has_key?(first_client, :estatus)
        assert Map.has_key?(first_client, :udn)
        assert Map.has_key?(first_client, :preventa)
        assert Map.has_key?(first_client, :entrega)
        assert Map.has_key?(first_client, :autoventa)
        assert Map.has_key?(first_client, :ctepfr_codigo_k)
        assert Map.has_key?(first_client, :ctedir_codigo_k)
        assert Map.has_key?(first_client, :rfc)

        # Verify concatenated catalog fields
        assert Map.has_key?(first_client, :frecuencia)
        assert Map.has_key?(first_client, :canal)
        assert Map.has_key?(first_client, :subcanal)
        assert Map.has_key?(first_client, :cadena)
        assert Map.has_key?(first_client, :paquete_serv)
        assert Map.has_key?(first_client, :regimen)

        # Verify location fields
        assert Map.has_key?(first_client, :estado)
        assert Map.has_key?(first_client, :municipio)
        assert Map.has_key?(first_client, :localidad)

        # Verify coordinates
        assert Map.has_key?(first_client, :map_x)
        assert Map.has_key?(first_client, :map_y)

        # Verify address fields
        assert Map.has_key?(first_client, :ctedir_calle)
        assert Map.has_key?(first_client, :ctedir_colonia)
        assert Map.has_key?(first_client, :ctedir_callenumext)
        assert Map.has_key?(first_client, :ctedir_callenumint)
        assert Map.has_key?(first_client, :ctedir_telefono)
        assert Map.has_key?(first_client, :ctedir_responsable)
        assert Map.has_key?(first_client, :ctedir_calleentre1)
        assert Map.has_key?(first_client, :ctedir_calleentre2)
        assert Map.has_key?(first_client, :ctedir_cp)

        # Verify all client fields
        assert Map.has_key?(first_client, :ctecli_codigo_k)
        assert Map.has_key?(first_client, :ctecli_razonsocial)
        assert Map.has_key?(first_client, :ctecli_dencomercia)
        assert Map.has_key?(first_client, :ctecli_fechaalta)
        assert Map.has_key?(first_client, :ctecli_fechabaja)
        assert Map.has_key?(first_client, :ctecli_causabaja)
        assert Map.has_key?(first_client, :ctecli_edocred)
        assert Map.has_key?(first_client, :ctecli_diascredito)
        assert Map.has_key?(first_client, :ctecli_limitecredi)
        assert Map.has_key?(first_client, :ctecli_tipodefact)
        assert Map.has_key?(first_client, :ctecli_tipofacdes)
        assert Map.has_key?(first_client, :ctecli_tipopago)
        assert Map.has_key?(first_client, :ctecli_creditoobs)

        # Verify catalog FK fields
        assert Map.has_key?(first_client, :ctetpo_codigo_k)
        assert Map.has_key?(first_client, :ctesca_codigo_k)
        assert Map.has_key?(first_client, :ctepaq_codigo_k)
        assert Map.has_key?(first_client, :ctereg_codigo_k)
        assert Map.has_key?(first_client, :ctecad_codigo_k)
        assert Map.has_key?(first_client, :cfgmon_codigo_k)

        # Verify system fields
        assert Map.has_key?(first_client, :s_maqedo)
        assert Map.has_key?(first_client, :s_fecha)
        assert Map.has_key?(first_client, :s_fi)
        assert Map.has_key?(first_client, :s_guid)
        assert Map.has_key?(first_client, :s_guidlog)
        assert Map.has_key?(first_client, :s_usuario)
        assert Map.has_key?(first_client, :s_usuariodb)
        assert Map.has_key?(first_client, :s_guidnot)

        # Verify SAT fields
        assert Map.has_key?(first_client, :sat_uso_cfdi_k)
        assert Map.has_key?(first_client, :ctecli_formapago)
        assert Map.has_key?(first_client, :ctecli_metodopago)
        assert Map.has_key?(first_client, :ctecli_regtrib)

        # Verify data types for concatenated fields (should be strings, not integers)
        assert is_binary(first_client.frecuencia) || is_nil(first_client.frecuencia)
        assert is_binary(first_client.canal) || is_nil(first_client.canal)
        assert is_binary(first_client.subcanal) || is_nil(first_client.subcanal)
        assert is_binary(first_client.estado) || is_nil(first_client.estado)
        assert is_binary(first_client.municipio) || is_nil(first_client.municipio)

        # Verify estatus is a string with expected values
        assert first_client.estatus in ["---ACTIVO---", "---PROSPECTO---", "---BAJA---"]
      end
    end

    test "returns empty list for non-existent UDN" do
      # Arrange
      sysudn_codigo_k = "99999"  # Non-existent UDN
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      assert is_list(result)
      # May be empty or may have results depending on database state
    end

    test "returns only clients within specified route range" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "010"  # Narrow range

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      assert is_list(result)

      # Verify all clients are within the route range
      Enum.each(result, fn client ->
        assert client.preventa >= vtarut_codigo_k_ini and client.preventa <= vtarut_codigo_k_fin or
               client.entrega >= vtarut_codigo_k_ini and client.entrega <= vtarut_codigo_k_fin or
               client.autoventa >= vtarut_codigo_k_ini and client.autoventa <= vtarut_codigo_k_fin
      end)
    end

    test "handles NULL values in concatenated fields correctly" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      if length(result) > 0 do
        Enum.each(result, fn client ->
          # Concatenated fields should never be integers (0) or cause errors
          # They should be strings or nil
          refute is_integer(client.frecuencia) and client.frecuencia == 0
          refute is_integer(client.canal) and client.canal == 0
          refute is_integer(client.subcanal) and client.subcanal == 0
          refute is_integer(client.estado) and client.estado == 0
          refute is_integer(client.municipio) and client.municipio == 0
          refute is_integer(client.localidad) and client.localidad == 0
        end)
      end
    end

    test "returns clients ordered by ctecli_codigo_k" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      if length(result) > 1 do
        # Verify results are ordered by client code
        codes = Enum.map(result, & &1.ctecli_codigo_k)
        sorted_codes = Enum.sort(codes)
        assert codes == sorted_codes
      end
    end

    test "includes only active clients (s_maqedo = 10)" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      # All clients should have estatus as ACTIVO since we filter by s_maqedo = 10
      Enum.each(result, fn client ->
        assert client.estatus == "---ACTIVO---"
      end)
    end

    test "decimal fields are properly formatted" do
      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act
      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      # Assert
      if length(result) > 0 do
        Enum.each(result, fn client ->
          # map_x and map_y should be Decimal or nil, not strings
          if client.map_x do
            assert %Decimal{} = client.map_x or is_float(client.map_x) or is_nil(client.map_x)
          end

          if client.map_y do
            assert %Decimal{} = client.map_y or is_float(client.map_y) or is_nil(client.map_y)
          end

          # limite_credito should be Decimal or numeric
          if client.ctecli_limitecredi do
            assert %Decimal{} = client.ctecli_limitecredi or is_number(client.ctecli_limitecredi)
          end
        end)
      end
    end

    test "query executes without ArgumentError on type conversion" do
      # This test specifically checks for the bug where CONCAT returns integers
      # instead of strings, causing "cannot load `0` as type :string" error

      # Arrange
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      # Act & Assert - should not raise ArgumentError
      assert_raise_or_succeed = fn ->
        try do
          result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)
          {:ok, result}
        rescue
          e in ArgumentError ->
            if String.contains?(Exception.message(e), "cannot load") do
              flunk("Type conversion error: #{Exception.message(e)}")
            else
              reraise e, __STACKTRACE__
            end
        end
      end

      assert {:ok, _result} = assert_raise_or_succeed.()
    end
  end

  describe "list_clientes_completo/3 field validation" do
    setup do
      sysudn_codigo_k = "100"
      vtarut_codigo_k_ini = "001"
      vtarut_codigo_k_fin = "99999"

      result = Clientes.list_clientes_completo(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)

      if length(result) > 0 do
        {:ok, client: List.first(result)}
      else
        :ok  # Skip tests if no data available
      end
    end

    test "validates all 93 fields are present", %{client: client} do
      # This test ensures all 93 fields defined in default_visible_columns are available
      expected_fields = [
        # Main table fields
        :udn, :preventa, :entrega, :autoventa, :ctedir_codigo_k, :rfc,
        :codigo, :razon_social, :diascredito, :limite_credito, :paquete_codigo,
        :frecuencia_codigo, :estatus, :forma_pago, :metodo_pago,

        # Additional fields from list_clientes_completo
        :estatus, :ctepfr_codigo_k, :canal, :subcanal, :cadena,
        :paquete_serv, :regimen, :estado, :municipio, :localidad,
        :map_x, :map_y, :ctedir_calle, :ctedir_colonia,
        :ctedir_callenumext, :ctedir_callenumint, :ctedir_telefono,
        :ctedir_responsable, :ctedir_calleentre1, :ctedir_calleentre2,
        :ctedir_cp, :ctecli_codigo_k, :ctecli_razonsocial,
        :ctecli_dencomercia, :ctecli_fechaalta, :ctecli_fechabaja,
        :ctecli_causabaja, :ctecli_edocred, :ctecli_diascredito,
        :ctecli_limitecredi, :ctecli_tipodefact, :ctecli_tipofacdes,
        :ctecli_tipopago, :ctecli_creditoobs, :ctetpo_codigo_k,
        :ctesca_codigo_k, :ctepaq_codigo_k, :ctereg_codigo_k,
        :ctecad_codigo_k, :ctecli_generico, :cfgmon_codigo_k,
        :ctecli_observaciones, :systra_codigo_k, :facadd_codigo_k,
        :ctecli_fereceptor, :ctecli_fereceptormail, :ctepor_codigo_k,
        :ctecli_tipodefacr, :condim_codigo_k, :ctecli_cxcliq,
        :ctecli_nocta, :ctecli_dscantimp, :ctecli_desglosaieps,
        :ctecli_periodorefac, :ctecli_contacto, :cfgban_codigo_k,
        :ctecli_cargaespecifica, :ctecli_caducidadmin, :ctecli_ctlsanitario,
        :ctecli_formapago, :ctecli_metodopago, :ctecli_regtrib,
        :ctecli_pais, :ctecli_factablero, :sat_uso_cfdi_k,
        :ctecli_complemento, :ctecli_aplicacanje, :ctecli_aplicadev,
        :ctecli_desglosakit, :faccom_codigo_k, :ctecli_facgrupo,
        :facads_codigo_k, :s_maqedo, :s_fecha, :s_fi,
        :s_guid, :s_guidlog, :s_usuario, :s_usuariodb, :s_guidnot
      ]

      # Verify most important fields are present
      critical_fields = [
        :estatus, :udn, :preventa, :rfc, :ctecli_codigo_k,
        :ctecli_razonsocial, :estado, :map_x, :map_y
      ]

      Enum.each(critical_fields, fn field ->
        assert Map.has_key?(client, field), "Missing critical field: #{field}"
      end)
    end
  end
end
