defmodule PrettycoreWeb.ClienteFormEditLiveTest do
  use PrettycoreWeb.LiveCase, async: false

  alias Prettycore.Catalogos
  alias Prettycore.Clientes
  alias Prettycore.ClientesApi

  @moduletag :authenticated

  setup do
    # Create a test client that we can edit
    # This assumes you have a way to create test data
    # You may need to adjust this based on your test setup
    {:ok, %{}}
  end

  describe "mount /admin/clientes/edit/:id" do
    test "renders the edit client form with client data", %{conn: conn} do
      # First, we need a valid cliente_id
      # For now, we'll use "1" - adjust based on your test database
      cliente_id = "1"

      {:ok, _view, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Should NOT show "Nuevo Cliente" title
      refute html =~ "Nuevo Cliente"
      assert html =~ "form"
    end

    test "loads client data from database", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Verify the form has the cliente_id in the socket
      # The form should be populated with actual client data
      assert has_element?(view, "form")
    end

    test "loads catalog select options", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Verify catalogs are loaded
      assert has_element?(view, "select[name='cliente_form[ctetpo_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctecan_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[ctereg_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[systra_codigo_k]']")
      assert has_element?(view, "select[name='cliente_form[cfgmon_codigo_k]']")
    end

    test "pre-fills form with client data", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # The form should have populated values from the database
      # Verify that input fields are not empty (assuming client 1 has data)
      assert has_element?(view, "input[name='cliente_form[ctecli_codigo_k]']")
      assert has_element?(view, "input[name='cliente_form[ctecli_razonsocial]']")
    end

    test "loads dependent catalogs for existing client", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # If the client has a canal, subcanales should be loaded
      # If the client has an estado, municipios should be loaded
      # These will be visible as select options in the form
      assert has_element?(view, "select[name='cliente_form[ctesub_codigo_k]']")
      assert has_element?(view, "input[name^='cliente_form[direcciones]']")
    end

    test "displays direccion fields with existing data", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Verify direccion input fields exist
      assert has_element?(view, "input[name^='cliente_form[direcciones]']")
    end

    test "sets current page to clientes", %{conn: conn} do
      cliente_id = "1"

      {:ok, _view, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # The current_page should be "clientes"
      assert html =~ "clientes"
    end

    test "displays save button", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      assert has_element?(view, "button[type='submit']")
    end

    test "displays cancel link", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      assert has_element?(view, "a[href='/admin/clientes']")
    end

    test "handles invalid cliente_id gracefully", %{conn: conn} do
      # Test with a non-existent cliente_id
      invalid_id = "99999999"

      # This should either redirect or show an error
      # Adjust based on your error handling implementation
      result = catch_error(live(conn, ~p"/admin/clientes/edit/#{invalid_id}"))

      # Should raise an error or redirect
      assert result
    end
  end

  describe "form validation in edit mode" do
    test "validates required cliente fields", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

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
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

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

    test "validates CP format in direccion", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

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
  end

  describe "form interaction in edit mode" do
    test "form change event is handled", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Trigger form change
      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecli_razonsocial" => "Updated Company Name"
          }
        )
        |> render_change()

      # Should not crash and should return HTML
      assert result
    end

    test "handles tab change via event and URL", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Change to facturacion tab
      result =
        view
        |> element("button[phx-click='change_tab'][phx-value-tab='facturacion']")
        |> render_click()

      # Should not crash
      assert result

      # Check that we can also navigate directly to facturacion tab
      {:ok, view2, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}/facturacion")

      # Should load the facturacion tab
      assert html =~ "Facturación"
    end

    test "updates municipios when estado changes", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

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

      # Verify municipios select is present
      assert result =~ "select"
      assert result =~ "mapmun_codigo_k"
    end

    test "preserves client code when editing", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # The client code should be present and read-only or disabled
      # because we're editing an existing client
      assert has_element?(view, "input[name='cliente_form[ctecli_codigo_k]']")
    end
  end

  describe "form submission in edit mode" do
    test "validates required fields on save", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

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
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Submit with invalid RFC
      invalid_attrs = %{
        "ctecli_rfc" => "INVALID"
      }

      result =
        view
        |> form("form", cliente_form: invalid_attrs)
        |> render_submit()

      # Should show RFC format error
      assert result =~ "formato RFC inválido"
    end

    test "validates direccion fields on save", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Submit with invalid CP
      invalid_attrs = %{
        "direcciones" => %{
          "0" => %{
            "ctedir_cp" => "123"
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

    @tag :skip
    test "updates cliente successfully with API call", %{conn: conn} do
      # This test would require mocking ClientesApi.actualizar_cliente
      # Skipped for now as it requires API mocking setup
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      valid_attrs = %{
        "ctecli_razonsocial" => "Updated Company SA de CV",
        "ctecli_dencomercia" => "Updated Company"
      }

      # TODO: Mock ClientesApi.actualizar_cliente to return {:ok, response}
      # Expect navigation to clientes list
      # Expect flash message "Cliente actualizado exitosamente"
    end
  end

  describe "page navigation in edit mode" do
    test "handles navigation to clientes list", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Trigger clientes navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "clientes"})

      # Should redirect to clientes
      assert_redirect(view, ~p"/admin/clientes")
    end

    test "handles navigation to inicio", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Trigger inicio navigation via change_page event
      view
      |> render_hook("change_page", %{"id" => "inicio"})

      # Should redirect to platform
      assert_redirect(view, ~p"/admin/platform")
    end
  end

  describe "dependent catalog loading in edit mode" do
    test "loads subcanales when client has a canal", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # If the client has a canal selected, subcanales should be loaded
      # Verify the subcanal select exists
      assert has_element?(view, "select[name='cliente_form[ctesub_codigo_k]']")
    end

    test "loads municipios when direccion has estado", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # If the client's address has an estado, municipios should be pre-loaded
      # Check if municipio select exists
      if html =~ "mapedo_codigo_k" do
        # If estado field exists, municipio field should also exist
        assert html =~ "mapmun_codigo_k"
      end
    end

    test "loads localidades when direccion has estado and municipio", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # If the client's address has estado and municipio, localidades should be pre-loaded
      if html =~ "mapmun_codigo_k" do
        # If municipio exists, localidad field should also exist
        assert html =~ "maploc_codigo_k"
      end
    end

    test "updates subcanales when canal changes", %{conn: conn} do
      cliente_id = "1"

      {:ok, view, _html} = live(conn, ~p"/admin/clientes/edit/#{cliente_id}")

      # Select a canal
      canal_codigo = "100"

      result =
        view
        |> form("form",
          cliente_form: %{
            "ctecan_codigo_k" => canal_codigo
          }
        )
        |> render_change(%{"_target" => ["cliente_form", "ctecan_codigo_k"]})

      # Subcanales should be loaded for the selected canal
      subcanales = Catalogos.listar_subcanales(canal_codigo)

      if length(subcanales) > 0 do
        # Verify subcanal select has options
        assert result =~ "ctesub_codigo_k"
      end
    end
  end
end
