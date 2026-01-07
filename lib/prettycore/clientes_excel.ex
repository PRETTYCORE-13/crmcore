defmodule Prettycore.ClientesExcel do
  @moduledoc """
  Genera archivos Excel con datos completos de clientes
  """

  alias Elixlsx.{Workbook, Sheet}

  @doc """
  Genera un archivo Excel con todos los clientes y TODOS sus campos

  ## Parámetros
    * sysudn_codigo_k - Código de unidad de negocio
    * vtarut_codigo_k_ini - Ruta inicial
    * vtarut_codigo_k_fin - Ruta final
    * visible_columns - Map con las columnas seleccionadas para exportar

  ## Retorna
    * Binario con el contenido del archivo Excel
  """
  def generar_excel(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin, visible_columns \\ %{}) do
    # Obtener TODOS los datos completos
    clientes = Prettycore.Clientes.list_clientes_completo(
      sysudn_codigo_k,
      vtarut_codigo_k_ini,
      vtarut_codigo_k_fin
    )

    # Determinar qué columnas exportar (solo las seleccionadas como visibles)
    columnas_a_exportar = get_columnas_visibles(visible_columns)

    # Crear encabezados
    headers = Enum.map(columnas_a_exportar, fn {_key, label} -> label end)

    # Crear filas de datos
    rows = Enum.map(clientes, fn cliente ->
      Enum.map(columnas_a_exportar, fn {key, _label} ->
        format_cell_value(Map.get(cliente, columna_real(key)))
      end)
    end)

    # Construir el workbook con configuración apropiada
    sheet = %Sheet{
      name: "Clientes",
      rows: [headers | rows]
    }

    workbook = %Workbook{
      sheets: [sheet]
    }

    # Generar el archivo Excel en memoria y retornar el binario
    {:ok, {_filename, excel_binary}} = Elixlsx.write_to_memory(workbook, "clientes.xlsx")
    excel_binary
  end

  # Obtiene las columnas visibles con sus etiquetas
  defp get_columnas_visibles(visible_columns) when visible_columns == %{} do
    # Si no se especifican columnas, exportar todas
    todas_las_columnas()
  end

  defp get_columnas_visibles(visible_columns) do
    todas = todas_las_columnas()

    # Filtrar solo las columnas marcadas como visibles
    Enum.filter(todas, fn {key, _label} ->
      Map.get(visible_columns, key, false) == true
    end)
  end

  # Mapeo de nombres de columnas de la vista a nombres en list_clientes_completo
  defp columna_real("udn"), do: :udn
  defp columna_real("preventa"), do: :preventa
  defp columna_real("entrega"), do: :entrega
  defp columna_real("autoventa"), do: :autoventa
  defp columna_real("codigo"), do: :ctecli_codigo_k
  defp columna_real("razon_social"), do: :ctecli_razonsocial
  defp columna_real("nombre_comercial"), do: :ctecli_dencomercia
  defp columna_real("telefono"), do: :ctedir_telefono
  defp columna_real("estado"), do: :estado
  defp columna_real("colonia"), do: :ctedir_colonia
  defp columna_real("calle"), do: :ctedir_calle
  defp columna_real("diascredito"), do: :ctecli_diascredito
  defp columna_real("limite_credito"), do: :ctecli_limitecredi
  defp columna_real("paquete_codigo"), do: :ctepaq_codigo_k
  defp columna_real("frecuencia_codigo"), do: :ctepfr_codigo_k
  defp columna_real("email_receptor"), do: :ctecli_fereceptormail
  defp columna_real("forma_pago"), do: :ctecli_formapago
  defp columna_real("metodo_pago"), do: :ctecli_metodopago
  defp columna_real("estatus"), do: :estatus
  defp columna_real("municipio"), do: :municipio
  defp columna_real("localidad"), do: :localidad
  # Para el resto que coinciden directamente con los nombres de BD:
  defp columna_real(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> :ctecli_codigo_k  # fallback
    end
  end


  # Define TODAS las columnas disponibles con sus etiquetas
  # Usa los nombres de la vista (los que están en los checkboxes)
  defp todas_las_columnas do
    [
      # Datos de ruta
      {"udn", "UDN"},
      {"preventa", "Preventa"},
      {"entrega", "Entrega"},
      {"autoventa", "Autoventa"},

      # Identificadores básicos (nombres de la vista)
      {"ctedir_codigo_k", "Código Dirección"},
      {"rfc", "RFC"},
      {"codigo", "Código Cliente"},
      {"razon_social", "Razón Social"},
      {"nombre_comercial", "Nombre Comercial"},
      {"telefono", "Teléfono"},
      {"diascredito", "Días Crédito"},
      {"limite_credito", "Límite Crédito"},
      {"paquete_codigo", "Paquete Código"},
      {"frecuencia_codigo", "Frecuencia Código"},
      {"email_receptor", "Email Receptor"},
      {"forma_pago", "Forma Pago"},
      {"metodo_pago", "Método Pago"},
      {"estatus", "Estatus"},
      {"estado", "Estado"},
      {"municipio", "Municipio"},
      {"localidad", "Localidad"},
      {"colonia", "Colonia"},
      {"calle", "Calle"},

      # Campos adicionales de dirección
      {"ctedir_callenumext", "Número Exterior"},
      {"ctedir_callenumint", "Número Interior"},
      {"ctedir_cp", "Código Postal"},
      {"ctedir_responsable", "Responsable"},
      {"ctedir_calleentre1", "Entre Calle 1"},
      {"ctedir_calleentre2", "Entre Calle 2"},

      # Coordenadas
      {"map_x", "Coordenada X"},
      {"map_y", "Coordenada Y"},

      # Catálogos
      {"frecuencia", "Frecuencia"},
      {"canal", "Canal"},
      {"subcanal", "Subcanal"},
      {"cadena", "Cadena"},
      {"paquete_serv", "Paquete Servicio"},
      {"regimen", "Régimen"},

      # Campos completos de cliente (nombres de BD)
      {"ctepfr_codigo_k", "Código Patrón Frecuencia"},
      {"ctecli_codigo_k", "Código Cliente (BD)"},
      {"ctecli_razonsocial", "Razón Social (BD)"},
      {"ctecli_dencomercia", "Nombre Comercial (BD)"},

      # Fechas
      {"ctecli_fechaalta", "Fecha Alta"},
      {"ctecli_fechabaja", "Fecha Baja"},
      {"ctecli_causabaja", "Causa Baja"},

      # Crédito
      {"ctecli_edocred", "Estado Crédito"},
      {"ctecli_diascredito", "Días Crédito"},
      {"ctecli_limitecredi", "Límite Crédito"},
      {"ctecli_creditoobs", "Observaciones Crédito"},

      # Facturación
      {"ctecli_tipodefact", "Tipo Factura"},
      {"ctecli_tipofacdes", "Tipo Factura Descripción"},
      {"ctecli_tipodefacr", "Tipo Factura Recurrente"},
      {"ctecli_tipopago", "Tipo Pago"},
      {"ctecli_formapago", "Forma Pago"},
      {"ctecli_metodopago", "Método Pago"},
      {"sat_uso_cfdi_k", "Uso CFDI"},
      {"ctecli_fereceptor", "Receptor FE"},
      {"ctecli_fereceptormail", "Email Receptor"},

      # Catálogos concatenados
      {"frecuencia", "Frecuencia"},
      {"canal", "Canal"},
      {"subcanal", "Subcanal"},
      {"cadena", "Cadena"},
      {"paquete_serv", "Paquete Servicio"},
      {"regimen", "Régimen"},

      # Ubicación
      {"estado", "Estado"},
      {"municipio", "Municipio"},
      {"localidad", "Localidad"},
      {"ctedir_colonia", "Colonia"},
      {"ctedir_calle", "Calle"},
      {"ctedir_callenumext", "Número Exterior"},
      {"ctedir_callenumint", "Número Interior"},
      {"ctedir_calleentre1", "Entre Calle 1"},
      {"ctedir_calleentre2", "Entre Calle 2"},
      {"ctedir_cp", "Código Postal"},

      # Coordenadas
      {"map_x", "Coordenada X"},
      {"map_y", "Coordenada Y"},

      # Contacto
      {"ctedir_responsable", "Responsable"},
      {"ctedir_telefono", "Teléfono"},
      {"ctedir_celular", "Celular"},
      {"ctedir_mail", "Email Dirección"},
      {"ctecli_contacto", "Contacto"},

      # Códigos de catálogos
      {"ctetpo_codigo_k", "Tipo Pago (Código)"},
      {"ctecan_codigo_k", "Canal (Código)"},
      {"ctesca_codigo_k", "Subcanal (Código)"},
      {"ctepaq_codigo_k", "Paquete (Código)"},
      {"ctereg_codigo_k", "Régimen (Código)"},
      {"ctecad_codigo_k", "Cadena (Código)"},

      # Configuración
      {"ctecli_generico", "Cliente Genérico"},
      {"cfgmon_codigo_k", "Moneda"},
      {"ctecli_pais", "País"},
      {"cfgreg_codigo_k", "Región Config"},
      {"satexp_codigo_k", "Exportación SAT"},
      {"catind_codigo_k", "Industria"},
      {"catpfi_codigo_k", "Perfil Fiscal"},

      # Observaciones
      {"ctecli_observaciones", "Observaciones"},

      # Sistema transaccional
      {"systra_codigo_k", "Sistema Transacción"},

      # Facturación adicional
      {"facadd_codigo_k", "Dirección Adicional"},
      {"ctepor_codigo_k", "Portafolio"},
      {"condim_codigo_k", "Concepto Dimensión"},
      {"faccom_codigo_k", "Factura Comercial"},
      {"facads_codigo_k", "Factura Adicional Servicio"},

      # Flags operativos
      {"ctecli_nocta", "Número Cuenta"},
      {"ctecli_dscantimp", "Descuento Cantidad Importe"},
      {"ctecli_desglosaieps", "Desglosa IEPS"},
      {"ctecli_periodorefac", "Periodo Refacturación"},
      {"cfgban_codigo_k", "Banco"},
      {"ctecli_cargaespecifica", "Carga Específica"},
      {"ctecli_caducidadmin", "Caducidad Mínima"},
      {"ctecli_ctlsanitario", "Control Sanitario"},
      {"ctecli_regtrib", "Régimen Tributario"},
      {"ctecli_factablero", "Factura Tablero"},
      {"ctecli_complemento", "Complemento"},
      {"ctecli_aplicacanje", "Aplica Canje"},
      {"ctecli_aplicadev", "Aplica Devolución"},
      {"ctecli_desglosakit", "Desglosa Kit"},
      {"ctecli_facgrupo", "Factura Grupo"},
      {"ctecli_cxcliq", "CXC Liquidación"},
      {"ctecli_cfdi_ver", "Versión CFDI"},

      # Rutas
      {"vtarut_codigo_k_pre", "Ruta Preventa"},
      {"vtarut_codigo_k_ent", "Ruta Entrega"},
      {"vtarut_codigo_k_aut", "Ruta Autoventa"},

      # Configuración dirección
      {"ctepfr_codigo_k", "Patrón Frecuencia"},
      {"cteclu_codigo_k", "Cluster"},
      {"ctezni_codigo_k", "Zona Influencia"},

      # Estado y ubicación mapa
      {"mapedo_codigo_k", "Estado (Código)"},
      {"mapmun_codigo_k", "Municipio (Código)"},
      {"maploc_codigo_k", "Localidad (Código)"},

      # Estatus
      {"estatus", "Estatus"},

      # Metadatos del sistema
      {"s_maqedo", "Estado Máquina"},
      {"s_fecha", "Fecha Sistema"},
      {"s_fi", "Fecha Inserción"},
      {"s_guid", "GUID"},
      {"s_guidlog", "GUID Log"},
      {"s_usuario", "Usuario"},
      {"s_usuariodb", "Usuario DB"},
      {"s_guidnot", "GUID Notificación"}
    ]
  end

  # Formatea el valor de una celda para Excel
  defp format_cell_value(nil), do: ""
  defp format_cell_value(%Decimal{} = d), do: Decimal.to_float(d)
  defp format_cell_value(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)
  defp format_cell_value(%DateTime{} = dt), do: DateTime.to_string(dt)
  defp format_cell_value(value) when is_binary(value), do: value
  defp format_cell_value(value) when is_integer(value), do: Integer.to_string(value)
  defp format_cell_value(value) when is_float(value), do: Float.to_string(value)
  defp format_cell_value(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  defp format_cell_value(value), do: inspect(value)
end
