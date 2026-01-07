defmodule Prettycore.ClientesApiTest do
  use ExUnit.Case, async: true

  alias Prettycore.ClientesApi

  describe "crear_cliente/2 data transformation" do
    test "transforms cliente data to correct API format with uppercase keys" do
      cliente_data = %{
        # Datos Básicos
        ctecli_codigo_k: "100",
        ctecli_razonsocial: "cliente generico 100",
        ctecli_dencomercia: "Abarrotes La Sirena",
        ctecli_rfc: "XAXX010101000",
        ctecli_fereceptormail: nil,
        ctecli_nocta: 1,
        ctecli_fechaalta: ~N[2023-11-23 00:00:00],
        ctecli_fechabaja: nil,
        ctecli_causabaja: nil,
        # Información de Crédito
        ctecli_edocred: 0,
        ctecli_diascredito: 0,
        ctecli_limitecredi: Decimal.new("0"),
        ctecli_creditoobs: nil,
        # Clasificación (Obligatorios NOT NULL)
        ctetpo_codigo_k: 100,
        ctecan_codigo_k: "100",
        ctesca_codigo_k: "100",
        ctepaq_codigo_k: "100",
        ctereg_codigo_k: "101",
        ctecad_codigo_k: nil,
        systra_codigo_k: "FRCTE_CLIENTE",
        cfgmon_codigo_k: "MXN",
        # Facturación (Catálogos SAT)
        ctecli_formapago: "01",
        ctecli_metodopago: "PUE",
        sat_uso_cfdi_k: "S01",
        cfgreg_codigo_k: "616",
        ctecli_regtrib: nil,
        # Catálogos Opcionales (Foreign Keys)
        facadd_codigo_k: nil,
        ctepor_codigo_k: nil,
        condim_codigo_k: nil,
        cfgban_codigo_k: nil,
        sysemp_codigo_k: nil,
        faccom_codigo_k: nil,
        facads_codigo_k: nil,
        cteseg_codigo_k: nil,
        catind_codigo_k: "3",
        catpfi_codigo_k: "1",
        satexp_codigo_k: "01",
        ctecli_pais: "MEX",
        # Flags (Valores por defecto)
        ctecli_generico: 1,
        ctecli_dscantimp: 1,
        ctecli_desglosaieps: 0,
        ctecli_periodorefac: 0,
        ctecli_cargaespecifica: 0,
        ctecli_caducidadmin: 0,
        ctecli_ctlsanitario: 0,
        ctecli_factablero: 1,
        ctecli_aplicacanje: 0,
        ctecli_aplicadev: 0,
        ctecli_desglosakit: 0,
        ctecli_facgrupo: 0,
        ctecli_timbracb: 0,
        ctecli_novalidavencimiento: 0,
        ctecli_cfdi_ver: 1,
        ctecli_aplicaregalo: 0,
        ctecli_noaceptafracciones: 0,
        ctecli_cxcliq: nil,
        ctecli_contacto: nil,
        ctecli_complemento: nil,
        ctecli_compatibilidad: nil,
        ctecli_nombre: nil,
        ctecli_prvporteofac: nil,
        ctecli_ecommerce: nil,
        ctecli_observaciones: nil,
        # Tipos de Facturación
        ctecli_tipodefact: 2,
        ctecli_tipofacdes: 0,
        ctecli_tipodefacr: nil,
        ctecli_tipopago: "01",
        # Sistema
        s_maqedo: "10",
        # Dirección
        direccion: %{
          ctecli_codigo_k: "100",
          ctedir_codigo_k: "1",
          ctecli_razonsocial: "cliente generico 100",
          ctecli_dencomercia: "Abarrotes La Sirena",
          ctedir_tipofis: 1,
          ctedir_tipoent: 1,
          ctedir_responsable: nil,
          ctedir_telefono: nil,
          ctedir_calle: "Lombardo toledano",
          ctedir_callenumext: "sn",
          ctedir_callenumint: nil,
          ctedir_colonia: nil,
          ctedir_calleentre1: nil,
          ctedir_calleentre2: nil,
          ctedir_cp: "50016",
          mapedo_codigo_k: 15,
          mapmun_codigo_k: 106,
          maploc_codigo_k: 180,
          map_x: "-99.6089096",
          map_y: "19.3048745",
          cteclu_codigo_k: "100",
          ctecor_codigo_k: nil,
          ctezni_codigo_k: "100",
          ctedir_observaciones: nil,
          ctepfr_codigo_k: "D",
          vtarut_codigo_k_pre: "20001",
          vtarut_codigo_k_ent: "30001",
          vtarut_codigo_k_cob: nil,
          vtarut_codigo_k_aut: nil,
          ctedir_ivafrontera: 0,
          systra_codigo_k: "FRCTE_DIRECCION",
          ctedir_secuencia: 0,
          ctedir_secuenciaent: 0,
          ctedir_geoubicacion: nil,
          vtarut_codigo_k_simpre: nil,
          vtarut_codigo_k_siment: nil,
          vtarut_codigo_k_simcob: nil,
          vtarut_codigo_k_simaut: nil,
          condim_codigo_k: nil,
          ctedir_celular: "10",
          ctedir_reqgeo: 0,
          ctedir_guidref: nil,
          ctepaq_codigo_k: "100",
          vtarut_codigo_k_sup: "10004",
          ctedir_mail: "SYS",
          ctedir_codigopostal: "50016",
          ctedir_municipio: nil,
          ctedir_estado: nil,
          ctedir_localidad: nil,
          ctevie_codigo_k: nil,
          ctesvi_codigo_k: nil,
          satcol_codigo_k: nil,
          ctedir_distancia: 1,
          ctedir_novalidavencimiento: 0,
          ctedir_edocred: 0,
          ctedir_diascredito: 0,
          ctedir_limitecredi: 0,
          ctedir_tipopago: 0,
          ctedir_creditoobs: 0,
          ctedir_tipodefacr: nil,
          cfgest_codigo_k: nil,
          ctedir_teladicional: nil,
          ctedir_mailadicional: nil,
          c_localidad_k: nil,
          c_municipio_k: nil,
          c_estado_k: nil,
          satcp_codigo_k: nil,
          ctedir_maildicional: nil
        }
      }

      # Call public function (made public with @doc false for testing)
      result = ClientesApi.transform_to_api_format(cliente_data)

      # Verify top level structure
      assert Map.has_key?(result, "clientes")
      assert is_list(result["clientes"])
      assert length(result["clientes"]) == 1

      cliente = List.first(result["clientes"])

      # Verify all keys are uppercase - Datos Básicos
      assert cliente["CTECLI_CODIGO_K"] == "100"
      assert cliente["CTECLI_RAZONSOCIAL"] == "cliente generico 100"
      assert cliente["CTECLI_DENCOMERCIA"] == "Abarrotes La Sirena"
      assert cliente["CTECLI_RFC"] == "XAXX010101000"
      assert cliente["CTECLI_FERECEPTORMAIL"] == nil
      assert cliente["CTECLI_NOCTA"] == 1
      assert cliente["CTECLI_FECHAALTA"] == "2023-11-23T00:00:00"
      assert cliente["CTECLI_FECHABAJA"] == nil
      assert cliente["CTECLI_CAUSABAJA"] == nil

      # Información de Crédito
      assert cliente["CTECLI_EDOCRED"] == 0
      assert cliente["CTECLI_DIASCREDITO"] == 0
      assert cliente["CTECLI_LIMITECREDI"] == 0.0
      assert cliente["CTECLI_CREDITOOBS"] == nil

      # Clasificación (Obligatorios NOT NULL)
      assert cliente["CTETPO_CODIGO_K"] == 100
      assert cliente["CTECAN_CODIGO_K"] == "100"
      assert cliente["CTESCA_CODIGO_K"] == "100"
      assert cliente["CTEPAQ_CODIGO_K"] == "100"
      assert cliente["CTEREG_CODIGO_K"] == "101"
      assert cliente["CTECAD_CODIGO_K"] == nil
      assert cliente["SYSTRA_CODIGO_K"] == "FRCTE_CLIENTE"
      assert cliente["CFGMON_CODIGO_K"] == "MXN"

      # Facturación (Catálogos SAT)
      assert cliente["CTECLI_FORMAPAGO"] == "01"
      assert cliente["CTECLI_METODOPAGO"] == "PUE"
      assert cliente["SAT_USO_CFDI_K"] == "S01"
      assert cliente["CFGREG_CODIGO_K"] == "616"
      assert cliente["CTECLI_REGTRIB"] == nil

      # Catálogos Opcionales (Foreign Keys)
      assert cliente["FACADD_CODIGO_K"] == nil
      assert cliente["CTEPOR_CODIGO_K"] == nil
      assert cliente["CONDIM_CODIGO_K"] == nil
      assert cliente["CFGBAN_CODIGO_K"] == nil
      assert cliente["SYSEMP_CODIGO_K"] == nil
      assert cliente["FACCOM_CODIGO_K"] == nil
      assert cliente["FACADS_CODIGO_K"] == nil
      assert cliente["CTESEG_CODIGO_K"] == nil
      assert cliente["CATIND_CODIGO_K"] == "3"
      assert cliente["CATPFI_CODIGO_K"] == "1"
      assert cliente["SATEXP_CODIGO_K"] == "01"
      assert cliente["CTECLI_PAIS"] == "MEX"

      # Flags (Valores por defecto)
      assert cliente["CTECLI_GENERICO"] == 1
      assert cliente["CTECLI_DSCANTIMP"] == 1
      assert cliente["CTECLI_DESGLOSAIEPS"] == 0
      assert cliente["CTECLI_PERIODOREFAC"] == 0
      assert cliente["CTECLI_CARGAESPECIFICA"] == 0
      assert cliente["CTECLI_CADUCIDADMIN"] == 0
      assert cliente["CTECLI_CTLSANITARIO"] == 0
      assert cliente["CTECLI_FACTABLERO"] == 1
      assert cliente["CTECLI_APLICACANJE"] == 0
      assert cliente["CTECLI_APLICADEV"] == 0
      assert cliente["CTECLI_DESGLOSAKIT"] == 0
      assert cliente["CTECLI_FACGRUPO"] == 0
      assert cliente["CTECLI_TIMBRACB"] == 0
      assert cliente["CTECLI_NOVALIDAVENCIMIENTO"] == 0
      assert cliente["CTECLI_CFDI_VER"] == 1
      assert cliente["CTECLI_APLICAREGALO"] == 0
      assert cliente["CTECLI_NOACEPTAFRACCIONES"] == 0
      assert cliente["CTECLI_CXCLIQ"] == nil
      assert cliente["CTECLI_CONTACTO"] == nil
      assert cliente["CTECLI_COMPLEMENTO"] == nil
      assert cliente["CTECLI_COMPATIBILIDAD"] == nil
      assert cliente["CTECLI_NOMBRE"] == nil
      assert cliente["CTECLI_PRVPORTEOFAC"] == nil
      assert cliente["CTECLI_ECOMMERCE"] == nil
      assert cliente["CTECLI_OBSERVACIONES"] == nil

      # Tipos de Facturación
      assert cliente["CTECLI_TIPODEFACT"] == 2
      assert cliente["CTECLI_TIPOFACDES"] == 0
      assert cliente["CTECLI_TIPODEFACR"] == nil
      assert cliente["CTECLI_TIPOPAGO"] == "01"

      # Sistema
      assert cliente["S_MAQEDO"] == "10"

      # Verify direcciones is an array (note: changed from "direccion" to "direcciones")
      assert Map.has_key?(cliente, "direccion")
      assert is_list(cliente["direccion"])
      assert length(cliente["direccion"]) == 1

      direccion = List.first(cliente["direccion"])

      # Verify direccion data
      assert direccion["CTECLI_CODIGO_K"] == "100"
      assert direccion["CTEDIR_CODIGO_K"] == "1"
      assert direccion["CTECLI_RAZONSOCIAL"] == "cliente generico 100"
      assert direccion["CTECLI_DENCOMERCIA"] == "Abarrotes La Sirena"
      assert direccion["CTEDIR_TIPOFIS"] == 1
      assert direccion["CTEDIR_TIPOENT"] == 1
      assert direccion["CTEDIR_RESPONSABLE"] == nil
      assert direccion["CTEDIR_TELEFONO"] == nil
      assert direccion["CTEDIR_CALLE"] == "Lombardo toledano"
      assert direccion["CTEDIR_CALLENUMEXT"] == "sn"
      assert direccion["CTEDIR_CALLENUMINT"] == nil
      assert direccion["CTEDIR_COLONIA"] == nil
      assert direccion["CTEDIR_CP"] == "50016"
      assert direccion["MAPEDO_CODIGO_K"] == 15
      assert direccion["MAPMUN_CODIGO_K"] == 106
      assert direccion["MAPLOC_CODIGO_K"] == 180
      assert direccion["MAP_X"] == "-99.6089096"
      assert direccion["MAP_Y"] == "19.3048745"
      assert direccion["CTECLU_CODIGO_K"] == "100"
      assert direccion["CTEZNI_CODIGO_K"] == "100"
      assert direccion["CTEPFR_CODIGO_K"] == "D"
      assert direccion["VTARUT_CODIGO_K_PRE"] == "20001"
      assert direccion["VTARUT_CODIGO_K_ENT"] == "30001"
      assert direccion["CTEDIR_CELULAR"] == "10"
      assert direccion["CTEDIR_MAIL"] == "SYS"
      assert direccion["CTEPAQ_CODIGO_K"] == "100"
      assert direccion["VTARUT_CODIGO_K_SUP"] == "10004"

      ClientesApi.crear_cliente(
        cliente_data,
        "bdIG5U6GDNIpCH58yMXG34m2xvrV+RateJhpSr6BE8IQ5pXYzN+iRAcNUmx/SwvarrCbK4B1hS3ODViMdi5mdg=="
      )
    end

    test "transforms direccion with uppercase keys" do
      direccion = %{
        ctedir_codigo_k: "1",
        ctedir_calle: "Reforma",
        ctedir_callenumext: "123",
        ctedir_callenumint: "A",
        ctedir_colonia: "Centro",
        ctedir_cp: "06000",
        mapedo_codigo_k: "09",
        mapmun_codigo_k: "015",
        maploc_codigo_k: "0001",
        map_x: "19.4326",
        map_y: "-99.1332",
        ctedir_responsable: "Juan Perez",
        ctedir_telefono: "5551234567",
        ctedir_celular: "5559876543",
        ctedir_mail: "contacto@example.com",
        vtarut_codigo_k_pre: "RUT001",
        vtarut_codigo_k_ent: "RUT002",
        vtarut_codigo_k_cob: "RUT003",
        vtarut_codigo_k_aut: "RUT004",
        ctepfr_codigo_k: "PFR001",
        cteclu_codigo_k: "CLU001",
        ctezni_codigo_k: "ZNI001"
      }

      cliente_data = %{
        ctecli_codigo_k: "100",
        ctecli_razonsocial: "Test",
        ctecli_dencomercia: "Test",
        ctecli_rfc: "ABC123",
        ctecli_fechaalta: ~N[2025-01-15 10:30:00],
        ctecli_edocred: 1,
        ctecli_diascredito: 30,
        ctecli_limitecredi: Decimal.new("0"),
        ctecli_tipodefact: 1,
        ctecli_formapago: "01",
        ctecli_metodopago: "PUE",
        sat_uso_cfdi_k: "G03",
        ctecli_fereceptormail: "test@test.com",
        ctetpo_codigo_k: "TPO001",
        ctecan_codigo_k: "CAN001",
        ctesca_codigo_k: "SCA001",
        ctepaq_codigo_k: "PAQ001",
        ctereg_codigo_k: "REG001",
        cfgmon_codigo_k: "MXN",
        ctecli_pais: "MEX",
        cfgreg_codigo_k: "601",
        satexp_codigo_k: "EXP001",
        catind_codigo_k: "IND001",
        catpfi_codigo_k: "PFI001",
        ctecli_generico: 0,
        ctecli_nocta: "123",
        ctecli_dscantimp: 0,
        ctecli_desglosaieps: 0,
        ctecli_factablero: 0,
        ctecli_aplicacanje: 0,
        ctecli_aplicadev: 0,
        ctecli_desglosakit: 0,
        ctecli_facgrupo: 0,
        ctecli_cfdi_ver: 4.0,
        systra_codigo_k: "TRA001",
        s_maqedo: "10",
        direccion: direccion
      }

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])
      direccion_result = List.first(cliente["direccion"])

      # Verify all direccion keys are uppercase
      # Identificación
      assert direccion_result["CTEDIR_CODIGO_K"] == "1"

      # Dirección Física
      assert direccion_result["CTEDIR_CALLE"] == "Reforma"
      assert direccion_result["CTEDIR_CALLENUMEXT"] == "123"
      assert direccion_result["CTEDIR_CALLENUMINT"] == "A"
      assert direccion_result["CTEDIR_COLONIA"] == "Centro"
      assert direccion_result["CTEDIR_CP"] == "06000"

      # Ubicación Geográfica
      assert direccion_result["MAPEDO_CODIGO_K"] == "09"
      assert direccion_result["MAPMUN_CODIGO_K"] == "015"
      assert direccion_result["MAPLOC_CODIGO_K"] == "0001"
      assert direccion_result["MAP_X"] == "19.4326"
      assert direccion_result["MAP_Y"] == "-99.1332"

      # Contacto
      assert direccion_result["CTEDIR_RESPONSABLE"] == "Juan Perez"
      assert direccion_result["CTEDIR_TELEFONO"] == "5551234567"
      assert direccion_result["CTEDIR_CELULAR"] == "5559876543"
      assert direccion_result["CTEDIR_MAIL"] == "contacto@example.com"

      # Rutas (FK → VTA_RUTA)
      assert direccion_result["VTARUT_CODIGO_K_PRE"] == "RUT001"
      assert direccion_result["VTARUT_CODIGO_K_ENT"] == "RUT002"
      assert direccion_result["VTARUT_CODIGO_K_COB"] == "RUT003"
      assert direccion_result["VTARUT_CODIGO_K_AUT"] == "RUT004"

      # Otros catálogos opcionales
      assert direccion_result["CTEPFR_CODIGO_K"] == "PFR001"
      assert direccion_result["CTECLU_CODIGO_K"] == "CLU001"
      assert direccion_result["CTEZNI_CODIGO_K"] == "ZNI001"
    end

    test "handles nil direccion correctly" do
      cliente_data = build_minimal_cliente_data(%{direccion: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      # direccion should be an empty list when nil
      assert cliente["direccion"] == [nil]
    end

    test "formats datetime correctly" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_fechaalta: ~N[2025-12-03 14:30:45]
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_FECHAALTA"] == "2025-12-03T14:30:45"
    end

    test "handles nil datetime" do
      cliente_data = build_minimal_cliente_data(%{ctecli_fechaalta: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_FECHAALTA"] == nil
    end

    test "formats decimal to float" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_limitecredi: Decimal.new("999999.99")
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 999_999.99
      assert is_float(cliente["CTECLI_LIMITECREDI"])
    end

    test "handles numeric limitecredi values" do
      cliente_data = build_minimal_cliente_data(%{ctecli_limitecredi: 50000})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 50000
    end

    test "handles nil limitecredi as 0.0" do
      cliente_data = build_minimal_cliente_data(%{ctecli_limitecredi: nil})

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      assert cliente["CTECLI_LIMITECREDI"] == 0.0
    end

    test "preserves required NOT NULL fields" do
      cliente_data =
        build_minimal_cliente_data(%{
          ctecli_codigo_k: "REQUIRED_CODE",
          ctecli_fechaalta: ~N[2025-01-01 00:00:00],
          ctetpo_codigo_k: "TIPO001",
          ctecan_codigo_k: "CANAL001",
          ctesca_codigo_k: "SUBCANAL001",
          ctereg_codigo_k: "REGIMEN001",
          systra_codigo_k: "TRANS001"
        })

      result = ClientesApi.transform_to_api_format(cliente_data)
      cliente = List.first(result["clientes"])

      # Verify required fields are present
      assert cliente["CTECLI_CODIGO_K"] == "REQUIRED_CODE"
      assert cliente["CTECLI_FECHAALTA"] == "2025-01-01T00:00:00"
      assert cliente["CTETPO_CODIGO_K"] == "TIPO001"
      assert cliente["CTECAN_CODIGO_K"] == "CANAL001"
      assert cliente["CTESCA_CODIGO_K"] == "SUBCANAL001"
      assert cliente["CTEREG_CODIGO_K"] == "REGIMEN001"
      assert cliente["SYSTRA_CODIGO_K"] == "TRANS001"
    end
  end

  # Helper to build minimal cliente data
  defp build_minimal_cliente_data(overrides) do
    defaults = %{
      # Datos Básicos
      ctecli_codigo_k: "100",
      ctecli_razonsocial: "Test Company",
      ctecli_dencomercia: "Test",
      ctecli_rfc: "TEST123456789",
      ctecli_fereceptormail: "test@test.com",
      ctecli_nocta: "123",
      ctecli_fechaalta: ~N[2025-01-15 10:00:00],
      # Información de Crédito
      ctecli_edocred: 1,
      ctecli_diascredito: 30,
      ctecli_limitecredi: Decimal.new("0"),
      # Clasificación (Obligatorios NOT NULL)
      ctetpo_codigo_k: "TPO001",
      ctecan_codigo_k: "CAN001",
      ctesca_codigo_k: "SCA001",
      ctereg_codigo_k: "REG001",
      systra_codigo_k: "TRA001",
      cfgmon_codigo_k: "MXN",
      # Facturación (Catálogos SAT)
      ctecli_formapago: "01",
      ctecli_metodopago: "PUE",
      sat_uso_cfdi_k: "G03",
      cfgreg_codigo_k: "601",
      # Catálogos Opcionales (Foreign Keys)
      ctepaq_codigo_k: "PAQ001",
      facadd_codigo_k: nil,
      ctepor_codigo_k: nil,
      condim_codigo_k: nil,
      ctecad_codigo_k: nil,
      cfgban_codigo_k: nil,
      sysemp_codigo_k: nil,
      faccom_codigo_k: nil,
      facads_codigo_k: nil,
      cteseg_codigo_k: nil,
      catind_codigo_k: "IND001",
      catpfi_codigo_k: "PFI001",
      satexp_codigo_k: "EXP001",
      ctecli_pais: "MEX",
      # Flags (Valores por defecto)
      ctecli_generico: 0,
      ctecli_dscantimp: 0,
      ctecli_desglosaieps: 0,
      ctecli_periodorefac: 0,
      ctecli_cargaespecifica: 0,
      ctecli_caducidadmin: 0,
      ctecli_ctlsanitario: 0,
      ctecli_factablero: 0,
      ctecli_aplicacanje: 0,
      ctecli_aplicadev: 0,
      ctecli_desglosakit: 0,
      ctecli_facgrupo: 0,
      ctecli_timbracb: 0,
      ctecli_novalidavencimiento: 0,
      ctecli_cfdi_ver: 4.0,
      ctecli_aplicaregalo: 0,
      ctecli_noaceptafracciones: 0,
      ctecli_cxcliq: 0,
      # Tipos de Facturación
      ctecli_tipodefact: 1,
      ctecli_tipofacdes: 0,
      ctecli_tipodefacr: 0,
      ctecli_tipopago: "99",
      # Sistema
      s_maqedo: "10",
      # Dirección
      direccion: nil
    }

    Map.merge(defaults, overrides)
  end
end
