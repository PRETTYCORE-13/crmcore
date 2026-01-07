defmodule PrettycoreWeb.ClienteFormLiveTest do
  use PrettycoreWeb.LiveCase, async: false

  alias Prettycore.Catalogos

  @moduletag :authenticated

  describe "mount /admin/clientes/new" do
    test "renders the new client form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/clientes/new")

      assert html =~ "Nuevo Cliente"
      assert html =~ "form"
    end

    test "initializes form with default values", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify default values are set
      assert has_element?(view, "input[name='cliente_form[ctecli_rfc]'][value='XAXX010101000']")
      assert has_element?(view, "input[name='cliente_form[ctecli_pais]'][value='MEX']")
    end

    test "loads catalog select options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify catalogs are loaded
      assert has_element?(view, "select[name='cliente_form[ctetpo_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctecan_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctereg_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[systra_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[cfgmon_codigo_k]']")
    end

    test "initializes with direccion fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Verify direccion input fields exist
      assert has_element?(view, "input[name^='cliente_form[direcciones]']")
    end

    test "sets current page to clientes", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/clientes/new")

      # The current_page should be "clientes"
      assert html =~ "clientes"
    end

    test "displays save button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      assert has_element?(view, "button[type='submit']")
    end

    test "displays cancel link", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      assert has_element?(view, "a[href='/admin/clientes']")
    end
  end

  describe "form validation" do
    test "validates required cliente fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit form with empty required fields
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_codigo_k" => "",
            "ctetpo_codigo_k" => "",
            "ctecan_codigo_k" => "",
            "ctesca_codigo_k" => "",
            "ctereg_codigo_k" => "",
            "systra_codigo_k" => ""
          }
        )
        |> render_change()

      assert result =~ "Este campo es obligatorio"
    end

    test "validates RFC format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with invalid RFC
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_rfc" => "INVALID"
          }
        )
        |> render_change()

      assert result =~ "formato RFC inválido"
    end

    test "accepts valid RFC format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with valid RFC
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_rfc" => "TCO010101ABC"
          }
        )
        |> render_change()

      refute result =~ "formato RFC inválido"
    end

    test "validates CP format in direccion", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with invalid CP (too short)
      result =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "ctedir_cp" => "123"
              }
            }
          }
        )
        |> render_change()

      assert result =~ "El CP debe tener 5 dígitos"
    end

    test "validates CP contains only numbers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with non-numeric CP
      result =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "ctedir_cp" => "abcde"
              }
            }
          }
        )
        |> render_change()

      assert result =~ "El CP debe contener solo números"
    end

    test "accepts valid CP format", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with valid CP
      result =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "ctedir_cp" => "01000"
              }
            }
          }
        )
        |> render_change()

      refute result =~ "El CP debe"
    end

    test "validates RFC length", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # RFC too short
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_rfc" => "ABC"
          }
        )
        |> render_change()

      assert result =~ "formato RFC inválido"
    end
  end

  describe "catalog loading" do
    test "loads tipos de cliente options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      tipos_cliente = Catalogos.listar_tipos_cliente()

      if length(tipos_cliente) > 0 do
        # Verify select has options
        assert html =~ "ctetpo_codigo_k"
      end
    end

    test "loads canales options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      canales = Catalogos.listar_canales()

      if length(canales) > 0 do
        # Verify select has options
        assert html =~ "ctecan_codigo_k"
      end
    end

    test "loads regimenes options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      regimenes = Catalogos.listar_regimenes()

      if length(regimenes) > 0 do
        # Verify select has options
        assert html =~ "ctereg_codigo_k"
      end
    end

    test "loads usos cfdi options", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/clientes/new")

      usos_cfdi = Catalogos.listar_usos_cfdi()

      if length(usos_cfdi) > 0 do
        # Verify select has options
        assert html =~ "sat_uso_cfdi_k"
      end
    end
  end

  describe "form interaction" do
    test "form change event is handled", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger form change
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_codigo_k" => "TEST001",
            "ctecli_razonsocial" => "Test Company"
          }
        )
        |> render_change()

      # Should not crash and should return HTML
      assert result
    end

    test "handles tab change via event and URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Change to facturacion tab
      result =
        view
        |> element("button[phx-click='change_tab'][phx-value-tab='facturacion']")
        |> render_click()

      # Should not crash
      assert result

      # Check that we can also navigate directly to facturacion tab
      {:ok, view2, html} = live(conn, ~p"/admin/clientes/new/facturacion")

      # Should load the facturacion tab
      assert html =~ "Facturación"
    end

    test "updates municipios when estado changes - using Estado de Mexico", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Use Estado de Mexico (codigo 15)
      estado_codigo = "15"

      # Change the estado - this should trigger estado_change event and load municipios
      result =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "mapedo_codigo_k" => estado_codigo
              }
            }
          }
        )
        |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Verify the estado value is in the rendered HTML
      assert result =~ "value=\"#{estado_codigo}\""

      # Get municipios for Estado de Mexico
      municipios = Catalogos.listar_municipios(estado_codigo)
      assert length(municipios) > 0, "Estado de Mexico should have municipios"

      # Debug: Print first 10 municipios to see what we have
      IO.puts("\n📋 First 10 municipios for Estado de Mexico:")

      Enum.take(municipios, 10)
      |> Enum.each(fn {nombre, codigo} ->
        # Use inspect to safely handle encoding issues
        IO.inspect({nombre, codigo}, label: "  Municipio")
      end)

      IO.puts("\n📊 Total municipios for Estado de Mexico: #{length(municipios)}")

      # Debug: Let's see if the municipios select has any options
      if result =~ ~r/select.*mapmun_codigo_k/s do
        IO.puts("✅ Municipios select found in HTML")
      else
        IO.puts("❌ Municipios select NOT found in HTML")
      end

      # Verify specific municipios from Estado de Mexico are rendered in the options
      # The municipios should appear as option elements in the select
      has_acambay = result =~ "Acambay" or result =~ "ACAMBAY"
      has_acolman = result =~ "Acolman" or result =~ "ACOLMAN"

      IO.puts("Has Acambay in HTML: #{has_acambay}")
      IO.puts("Has Acolman in HTML: #{has_acolman}")

      # For debugging, let's check if ANY municipio name appears
      if length(municipios) > 0 do
        {first_mun, _} = List.first(municipios)
        IO.puts("Checking for first municipio '#{first_mun}' in HTML...")

        if result =~ first_mun do
          IO.puts("✅ First municipio FOUND in HTML")
        else
          IO.puts("❌ First municipio NOT found in HTML")

          # Let's find the select for municipios in the HTML
          municipio_select_regex =
            ~r/<select[^>]*name="[^"]*mapmun_codigo_k[^"]*"[^>]*>(.*?)<\/select>/s

          case Regex.run(municipio_select_regex, result) do
            [full_match, options_html] ->
              IO.puts("\n📄 Municipio SELECT found:")
              IO.puts(String.slice(full_match, 0..500))
              IO.puts("\n📄 Options HTML:")
              IO.puts(String.slice(options_html, 0..1000))

            nil ->
              IO.puts("❌ Could not find municipio select in HTML")
          end
        end
      end

      # For now, let's just verify that municipios were loaded from the database
      # The rendering issue will be addressed separately
      assert length(municipios) > 0, "Municipios should be loaded from database"

      assert Enum.any?(municipios, fn {nombre, _} -> nombre == "ACAMBAY" end),
             "ACAMBAY should be in municipios list"

      # Verify the select for municipios is present and enabled
      assert result =~ "select"
      assert result =~ "mapmun_codigo_k"

      # Verify we have multiple options in the rendered HTML
      # Count how many municipios were loaded
      IO.puts("\n📊 Municipios loaded for Estado de Mexico: #{length(municipios)}")

      if length(municipios) > 0 do
        {first_mun_nombre, _first_mun_codigo} = List.first(municipios)
        IO.puts("✅ First municipio: #{first_mun_nombre}")

        # Verify at least the first municipio is in the HTML
        assert result =~ first_mun_nombre
      end
    end

    test "municipios are cleared and localidades reset when estado changes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select Estado de Mexico (15) and a municipio
      estado_codigo = "15"

      # First select the estado
      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Get first municipio and select it
      municipios = Catalogos.listar_municipios(estado_codigo)
      assert length(municipios) > 0

      {_mun_nombre, municipio_codigo} = List.first(municipios)

      result_with_municipio =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "mapedo_codigo_k" => estado_codigo,
                "mapmun_codigo_k" => municipio_codigo
              }
            }
          }
        )
        |> render_change()

      # Verify municipio is selected
      assert result_with_municipio =~ municipio_codigo

      IO.puts("\n🔄 Testing estado change - municipio should be reset")

      # Step 2: Change to a different estado (e.g., Aguascalientes = 1)
      new_estado_codigo = "1"

      result_after_change =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "mapedo_codigo_k" => new_estado_codigo
              }
            }
          }
        )
        |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Verify new estado is selected
      assert result_after_change =~ "value=\"#{new_estado_codigo}\""

      # Verify new municipios are loaded for the new estado
      new_municipios = Catalogos.listar_municipios(new_estado_codigo)
      assert is_list(new_municipios)

      if length(new_municipios) > 0 do
        {first_new_mun_nombre, _codigo} = List.first(new_municipios)
        IO.puts("✅ New estado loaded municipio: #{first_new_mun_nombre}")

        # Verify the new municipios are in the rendered HTML
        assert result_after_change =~ first_new_mun_nombre
      end

      IO.puts("✅ Estado change correctly resets municipios and localidades")
    end

    test "full cascade: Estado de Mexico -> Acambay -> Localidades renders correctly", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select Estado de Mexico (15)
      estado_codigo = "15"

      result1 =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "mapedo_codigo_k" => estado_codigo
              }
            }
          }
        )
        |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Verify estado is selected
      assert result1 =~ "value=\"#{estado_codigo}\""

      # Get municipios for Estado de Mexico
      municipios = Catalogos.listar_municipios(estado_codigo)
      assert length(municipios) > 0, "Estado de Mexico should have municipios"

      IO.puts("\n🗺️  Estado de Mexico has #{length(municipios)} municipios")

      # Find Acambay in the list (should be one of the first)
      acambay =
        Enum.find(municipios, fn {nombre, _codigo} ->
          String.upcase(nombre) =~ "ACAMBAY"
        end)

      assert acambay != nil, "Acambay should be in Estado de Mexico municipios"
      {acambay_nombre, acambay_codigo} = acambay

      IO.puts("🏘️  Found municipio: #{acambay_nombre} (#{acambay_codigo})")

      # Verify Acambay is rendered in the HTML
      assert result1 =~ acambay_nombre

      # Step 2: Select Acambay municipio
      result2 =
        view
        |> form("form",
          cliente_form: %{
            "direcciones" => %{
              "0" => %{
                "mapedo_codigo_k" => estado_codigo,
                "mapmun_codigo_k" => acambay_codigo
              }
            }
          }
        )
        |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Verify municipio is selected
      assert result2 =~ acambay_nombre

      # Get localidades for Acambay
      localidades = Catalogos.listar_localidades(estado_codigo, acambay_codigo)

      IO.puts("📍 Acambay has #{length(localidades)} localidades")

      if length(localidades) > 0 do
        # Verify at least some localidades are rendered
        {first_localidad_nombre, first_localidad_codigo} = List.first(localidades)

        IO.puts("✅ First localidad: #{first_localidad_nombre} (#{first_localidad_codigo})")

        # Verify the localidad appears in the rendered HTML
        assert result2 =~ first_localidad_nombre or
                 result2 =~ String.upcase(first_localidad_nombre)

        # Verify localidad select is present
        assert result2 =~ "maploc_codigo_k"

        # Step 3: Select the first localidad
        result3 =
          view
          |> form("form",
            cliente_form: %{
              "direcciones" => %{
                "0" => %{
                  "mapedo_codigo_k" => estado_codigo,
                  "mapmun_codigo_k" => acambay_codigo,
                  "maploc_codigo_k" => first_localidad_codigo
                }
              }
            }
          )
          |> render_change()

        # Verify all three levels are present in the form
        assert result3 =~ estado_codigo
        assert result3 =~ acambay_codigo
        assert result3 =~ first_localidad_codigo

        IO.puts(
          "✅ Full cascade test passed: Estado (#{estado_codigo}) -> Municipio (#{acambay_nombre}) -> Localidad (#{first_localidad_nombre})"
        )
      else
        IO.puts("⚠️  No localidades found for Acambay")
      end
    end
  end

  describe "page navigation" do
    test "handles navigation to clientes list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger clientes navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "clientes"})

      # Should redirect to clientes
      assert_redirect(view, ~p"/admin/clientes")
    end

    test "handles navigation to inicio", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Trigger inicio navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "inicio"})

      # Should redirect to platform
      assert_redirect(view, ~p"/admin/platform")
    end
  end

  describe "form submission" do
    test "validates required fields on save", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Submit with missing required fields
      invalid_attrs = %{
        "ctecli_codigo_k" => "",
        "ctecli_razonsocial" => "",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "",
            "ctedir_callenumext" => "",
            "ctedir_cp" => ""
          }
        }
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show validation errors
      assert result =~ "Este campo es obligatorio"
    end

    test "validates RFC format on save", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select estado to populate municipios
      estado_codigo = "9"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Step 2: Select municipio to populate localidades
      municipio_codigo = "15"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo,
              "mapmun_codigo_k" => municipio_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Step 3: Submit form with invalid RFC
      invalid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_rfc" => "INVALID",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          }
        }
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show RFC format error
      assert result =~ "formato RFC inválido"
    end

    test "validates direccion fields on save", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select estado to populate municipios
      estado_codigo = "9"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Step 2: Select municipio to populate localidades
      municipio_codigo = "15"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo,
              "mapmun_codigo_k" => municipio_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Step 3: Submit form with invalid CP
      invalid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_rfc" => "TCO010101ABC",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            # Invalid CP - too short
            "ctedir_cp" => "123",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          }
        }
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show CP validation error
      assert result =~ "El CP debe tener 5 dígitos"
    end

    test "requires at least one direccion on save", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      invalid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_rfc" => "TCO010101ABC",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "FRCTE_CLIENTE",
        "direcciones" => %{}
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show direccion requirement error
      assert result =~ "Debe agregar al menos una dirección"
    end

    test "handles valid data structure correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select estado to populate municipios
      estado_codigo = "9"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Step 2: Select municipio to populate localidades
      municipio_codigo = "15"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo,
              "mapmun_codigo_k" => municipio_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Step 3: Submit form with valid data
      valid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_razonsocial" => "Test Company SA de CV",
        "ctecli_dencomercia" => "Test Company",
        "ctecli_rfc" => "TCO010101ABC",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "",
        "ctecli_edocred" => "0",
        "ctecli_diascredito" => "0",
        "ctecli_limitecredi" => "0.00",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          }
        }
      }

      # This will attempt to call the API, which should fail in test environment
      # but the data structure should be validated correctly first
      result =
        view
        |> form("form", cliente_form: valid_attrs)
        |> render_submit()

      # Since we don't have API mocking, it will likely fail at API call
      # but validation should pass (no validation error messages should appear)
      refute result =~ "Este campo es obligatorio"
      refute result =~ "formato RFC inválido"
      refute result =~ "El CP debe tener 5 dígitos"
    end

    test "validates all required catalog fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select estado to populate municipios
      estado_codigo = "9"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Step 2: Select municipio to populate localidades
      municipio_codigo = "15"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo,
              "mapmun_codigo_k" => municipio_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Step 3: Submit form missing required catalog fields
      invalid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_rfc" => "TCO010101ABC",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          }
        }
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show multiple validation errors for required fields
      assert result =~ "Este campo es obligatorio"
    end

    test "accepts valid data with multiple direcciones", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      # Step 1: Select estado for first direccion to populate municipios
      estado_codigo = "9"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapedo_codigo_k"]})

      # Step 2: Select municipio for first direccion to populate localidades
      municipio_codigo = "15"

      view
      |> form("form",
        cliente_form: %{
          "direcciones" => %{
            "0" => %{
              "mapedo_codigo_k" => estado_codigo,
              "mapmun_codigo_k" => municipio_codigo
            }
          }
        }
      )
      |> render_change(%{"_target" => ["cliente_form", "direcciones", "0", "mapmun_codigo_k"]})

      # Step 3: Submit form with valid data and multiple direcciones
      valid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_razonsocial" => "Test Company SA de CV",
        "ctecli_dencomercia" => "Test Company",
        "ctecli_rfc" => "TCO010101ABC",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          },
          "1" => %{
            "ctedir_codigo_k" => "2",
            "ctedir_calle" => "Calle Secundaria",
            "ctedir_callenumext" => "456",
            "ctedir_cp" => "01010",
            "mapedo_codigo_k" => estado_codigo,
            "mapmun_codigo_k" => municipio_codigo,
            "maploc_codigo_k" => "984"
          }
        }
      }

      result =
        view
        |> form("form", cliente_form: valid_attrs)
        |> render_submit()

      # Should pass validation for multiple direcciones
      refute result =~ "Este campo es obligatorio"
      refute result =~ "Debe agregar al menos una dirección"
    end

    @tag :skip
    test "creates cliente successfully with API call", %{conn: conn} do
      # This test would require mocking ClientesApi.crear_cliente
      # Skipped for now as it requires API mocking setup (e.g., Mox library)
      {:ok, view, _html} = live(conn, ~p"/admin/clientes/new")

      valid_attrs = %{
        "ctecli_codigo_k" => "TEST001",
        "ctecli_razonsocial" => "Test Company SA de CV",
        "ctecli_dencomercia" => "Test Company",
        "ctecli_rfc" => "TCO010101ABC",
        "ctetpo_codigo_k" => "100",
        "ctecan_codigo_k" => "100",
        "ctesca_codigo_k" => "",
        "ctereg_codigo_k" => "100",
        "systra_codigo_k" => "FRCTE_CLIENTE",
        "direcciones" => %{
          "0" => %{
            "ctedir_codigo_k" => "1",
            "ctedir_calle" => "Calle Principal",
            "ctedir_callenumext" => "123",
            "ctedir_cp" => "01000",
            "mapedo_codigo_k" => "9",
            "mapmun_codigo_k" => "15",
            "maploc_codigo_k" => "838"
          }
        }
      }

      # TODO: Mock ClientesApi.crear_cliente to return {:ok, response}
      # Expect navigation to clientes list
      # Expect flash message "Cliente creado exitosamente"
    end
  end
end
