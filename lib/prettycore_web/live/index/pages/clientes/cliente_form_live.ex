defmodule PrettycoreWeb.ClienteFormLive do
  use PrettycoreWeb, :live_view_admin

  alias Prettycore.ClientesApi
  alias Prettycore.Clientes
  alias Prettycore.Auth.User
  alias Prettycore.Repo
  alias Prettycore.Catalogos
  import Ecto.Query

  # Esquema embedded para Dirección
  defmodule DireccionForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      # Datos de identificación (obligatorios)
      field(:ctedir_codigo_k, :string)
      field(:ctedir_responsable, :string)
      field(:ctedir_telefono, :string)

      # Dirección física (obligatorios)
      field(:ctedir_calle, :string)
      field(:ctedir_callenumext, :string)
      field(:ctedir_callenumint, :string)
      field(:ctedir_colonia, :string)
      field(:ctedir_cp, :string)

      # Contacto
      field(:ctedir_celular, :string)
      field(:ctedir_mail, :string)

      # Ubicación geográfica (obligatorios)
      field(:mapedo_codigo_k, :integer)
      field(:mapmun_codigo_k, :integer)
      field(:maploc_codigo_k, :integer)
      field(:map_x, :string)
      field(:map_y, :string)

      # Rutas (varias obligatorias según tipo)
      field(:vtarut_codigo_k_pre, :string)
      field(:vtarut_codigo_k_ent, :string)
      field(:vtarut_codigo_k_cob, :string)
      field(:vtarut_codigo_k_aut, :string)
      field(:vtarut_codigo_k_simpre, :string)
      field(:vtarut_codigo_k_siment, :string)
      field(:vtarut_codigo_k_simcob, :string)
      field(:vtarut_codigo_k_simaut, :string)
      field(:vtarut_codigo_k_sup, :string)

      # Configuración y catálogos
      field(:ctepfr_codigo_k, :string)
      field(:cteclu_codigo_k, :string)
      field(:ctezni_codigo_k, :string)
      field(:ctecor_codigo_k, :string)
      field(:condim_codigo_k, :string)
      field(:ctepaq_codigo_k, :string)

      # Embarque
      field(:ctevie_codigo_k, :string)
      field(:ctesvi_codigo_k, :string)

      # SAT y CFDI 4.0
      field(:satcp_codigo_k, :string)
      field(:satcol_codigo_k, :string)
      field(:c_estado_k, :string)
      field(:c_municipio_k, :string)
      field(:c_localidad_k, :string)

      # Estrategia
      field(:cfgest_codigo_k, :string)

      # Flags (valores por defecto según spec)
      field(:ctedir_tipofis, :string, default: "0")
      field(:ctedir_tipoent, :string, default: "0")
      field(:ctedir_ivafrontera, :string, default: "0")
      field(:ctedir_secuencia, :integer, default: 0)
      field(:ctedir_secuenciaent, :integer, default: 0)
      field(:ctedir_reqgeo, :integer, default: 0)
      field(:ctedir_distancia, :decimal, default: Decimal.new("1.0000"))
      field(:ctedir_novalidavencimiento, :integer, default: 0)
      field(:ctedir_edocred, :integer, default: 0)
      field(:ctedir_diascredito, :integer, default: 0)
      field(:ctedir_limitecredi, :decimal, default: Decimal.new("0"))
      field(:ctedir_tipopago, :integer, default: 0)
      field(:ctedir_tipodefacr, :integer, default: 0)
      field(:s_maqedo, :integer, default: 0)
    end

    def changeset(direccion, attrs) do
      changeset =
        direccion
        |> cast(attrs, [
          # Identificación
          :ctedir_codigo_k,
          :ctedir_responsable,
          :ctedir_telefono,
          # Dirección física
          :ctedir_calle,
          :ctedir_callenumext,
          :ctedir_callenumint,
          :ctedir_colonia,
          :ctedir_cp,
          # Contacto
          :ctedir_celular,
          :ctedir_mail,
          # Ubicación geográfica
          :mapedo_codigo_k,
          :mapmun_codigo_k,
          :maploc_codigo_k,
          :map_x,
          :map_y,
          # Rutas
          :vtarut_codigo_k_pre,
          :vtarut_codigo_k_ent,
          :vtarut_codigo_k_cob,
          :vtarut_codigo_k_aut,
          :vtarut_codigo_k_simpre,
          :vtarut_codigo_k_siment,
          :vtarut_codigo_k_simcob,
          :vtarut_codigo_k_simaut,
          :vtarut_codigo_k_sup,
          # Configuración y catálogos
          :ctepfr_codigo_k,
          :cteclu_codigo_k,
          :ctezni_codigo_k,
          :ctecor_codigo_k,
          :condim_codigo_k,
          :ctepaq_codigo_k,
          # Embarque
          :ctevie_codigo_k,
          :ctesvi_codigo_k,
          # SAT y CFDI 4.0
          :satcp_codigo_k,
          :satcol_codigo_k,
          :c_estado_k,
          :c_municipio_k,
          :c_localidad_k,
          # Estrategia
          :cfgest_codigo_k,
          # Flags
          :ctedir_tipofis,
          :ctedir_tipoent,
          :ctedir_ivafrontera,
          :ctedir_secuencia,
          :ctedir_secuenciaent,
          :ctedir_reqgeo,
          :ctedir_distancia,
          :ctedir_novalidavencimiento,
          :ctedir_edocred,
          :ctedir_diascredito,
          :ctedir_limitecredi,
          :ctedir_tipopago,
          :ctedir_tipodefacr,
          :s_maqedo
        ])

      # Solo validar si la dirección tiene al menos un campo lleno (no está completamente vacía)
      if direccion_tiene_datos?(changeset) do
        changeset
        |> validate_required(
          [
            # Campos obligatorios NOT NULL de CTE_DIRECCION
            :ctedir_codigo_k,
            :ctedir_calle,
            :ctedir_callenumext,
            :ctedir_cp,
            :mapedo_codigo_k,
            :mapmun_codigo_k,
            :maploc_codigo_k
          ],
          message: "Este campo es obligatorio"
        )
        |> validate_length(:ctedir_cp, min: 5, max: 5, message: "El CP debe tener 5 dígitos")
        |> validate_format(:ctedir_cp, ~r/^\d{5}$/, message: "El CP debe contener solo números")
      else
        changeset
      end
    end

    defp direccion_tiene_datos?(changeset) do
      # Verificar si alguno de los campos clave tiene valor
      campos_clave = [:ctedir_calle, :ctedir_callenumext, :ctedir_cp, :ctedir_codigo_k]

      Enum.any?(campos_clave, fn campo ->
        valor = get_change(changeset, campo) || get_field(changeset, campo)
        valor != nil && valor != ""
      end)
    end
  end

  # Esquema embedded para Cliente
  defmodule ClienteForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      # Identificación (requeridos)
      field(:ctecli_codigo_k, :string)
      field(:ctecli_razonsocial, :string)
      field(:ctecli_dencomercia, :string)
      field(:ctecli_rfc, :string, default: "XAXX010101000")

      # Fechas (requerido)
      field(:ctecli_fechaalta, :date)

      # Crédito
      field(:ctecli_edocred, :integer, default: 0)
      field(:ctecli_diascredito, :integer, default: 0)
      field(:ctecli_limitecredi, :decimal, default: Decimal.new("0.0000"))

      # Facturación
      field(:ctecli_tipodefact, :string)
      field(:ctecli_tipofacdes, :string)
      field(:ctecli_tipodefacr, :boolean, default: false)
      field(:ctecli_formapago, :string)
      field(:ctecli_metodopago, :string)
      field(:ctecli_tipopago, :string, default: "99")
      field(:sat_uso_cfdi_k, :string, default: "G01")
      field(:ctecli_fereceptormail, :string)

      # Catálogos obligatorios (NOT NULL)
      field(:ctetpo_codigo_k, :string)
      field(:ctecan_codigo_k, :string)
      field(:ctesca_codigo_k, :string)
      field(:ctereg_codigo_k, :string)
      field(:systra_codigo_k, :string)

      # Catálogos opcionales con foreign keys
      field(:ctepaq_codigo_k, :string)
      field(:facadd_codigo_k, :string)
      field(:ctepor_codigo_k, :string)
      field(:condim_codigo_k, :string)
      field(:ctecad_codigo_k, :string)
      field(:cfgban_codigo_k, :string)
      field(:sysemp_codigo_k, :string)
      field(:faccom_codigo_k, :string)
      field(:facads_codigo_k, :string)
      field(:cteseg_codigo_k, :string)
      field(:cfgmon_codigo_k, :string)
      field(:catind_codigo_k, :string)
      field(:catpfi_codigo_k, :string)

      # Configuración regional
      field(:ctecli_pais, :string, default: "MEX")
      field(:cfgreg_codigo_k, :string, default: "601")
      field(:satexp_codigo_k, :string, default: "01")

      # Flags (valores por defecto según spec)
      field(:ctecli_generico, :integer, default: 0)
      field(:ctecli_nocta, :string)
      field(:ctecli_dscantimp, :boolean, default: true)
      field(:ctecli_desglosaieps, :boolean, default: false)
      field(:ctecli_periodorefac, :integer, default: 0)
      field(:ctecli_cargaespecifica, :integer, default: 0)
      field(:ctecli_caducidadmin, :integer, default: 0)
      field(:ctecli_ctlsanitario, :integer, default: 0)
      field(:ctecli_factablero, :integer, default: 0)
      field(:ctecli_aplicacanje, :integer, default: 0)
      field(:ctecli_aplicadev, :integer, default: 0)
      field(:ctecli_desglosakit, :boolean, default: false)
      field(:ctecli_facgrupo, :integer, default: 0)
      field(:ctecli_timbracb, :integer, default: 0)
      field(:ctecli_novalidavencimiento, :integer, default: 0)
      field(:ctecli_cfdi_ver, :string)
      field(:ctecli_aplicaregalo, :integer, default: 0)
      field(:ctecli_noaceptafracciones, :integer, default: 0)
      field(:ctecli_cxcliq, :integer, default: 0)

      # Sistema (valores automáticos)
      field(:s_maqedo, :integer, default: 0)

      # Direcciones embebidas (múltiples)
      embeds_many(:direcciones, DireccionForm)
    end

    def changeset(cliente, attrs) do
      cliente
      |> cast(attrs, [
        # Identificación
        :ctecli_codigo_k,
        :ctecli_razonsocial,
        :ctecli_dencomercia,
        :ctecli_rfc,
        # Fechas
        :ctecli_fechaalta,
        # Crédito
        :ctecli_edocred,
        :ctecli_diascredito,
        :ctecli_limitecredi,
        # Facturación
        :ctecli_tipodefact,
        :ctecli_tipofacdes,
        :ctecli_tipodefacr,
        :ctecli_formapago,
        :ctecli_metodopago,
        :ctecli_tipopago,
        :sat_uso_cfdi_k,
        :ctecli_fereceptormail,
        # Catálogos obligatorios
        :ctetpo_codigo_k,
        :ctecan_codigo_k,
        :ctesca_codigo_k,
        :ctereg_codigo_k,
        :systra_codigo_k,
        # Catálogos opcionales
        :ctepaq_codigo_k,
        :facadd_codigo_k,
        :ctepor_codigo_k,
        :condim_codigo_k,
        :ctecad_codigo_k,
        :cfgban_codigo_k,
        :sysemp_codigo_k,
        :faccom_codigo_k,
        :facads_codigo_k,
        :cteseg_codigo_k,
        :cfgmon_codigo_k,
        :catind_codigo_k,
        :catpfi_codigo_k,
        # Configuración regional
        :ctecli_pais,
        :cfgreg_codigo_k,
        :satexp_codigo_k,
        # Flags
        :ctecli_generico,
        :ctecli_nocta,
        :ctecli_dscantimp,
        :ctecli_desglosaieps,
        :ctecli_periodorefac,
        :ctecli_cargaespecifica,
        :ctecli_caducidadmin,
        :ctecli_ctlsanitario,
        :ctecli_factablero,
        :ctecli_aplicacanje,
        :ctecli_aplicadev,
        :ctecli_desglosakit,
        :ctecli_facgrupo,
        :ctecli_timbracb,
        :ctecli_novalidavencimiento,
        :ctecli_cfdi_ver,
        :ctecli_aplicaregalo,
        :ctecli_noaceptafracciones,
        :ctecli_cxcliq,
        :s_maqedo
      ])
      |> cast_embed(:direcciones, required: false)
      |> put_default_fechaalta()
      |> validate_required(
        [
          # Campos obligatorios NOT NULL - validar solo al guardar
          :ctecli_codigo_k
        ],
        message: "Este campo es obligatorio"
      )
      |> validate_direcciones()
      |> validate_length(:ctecli_rfc, min: 12, max: 13)
      |> validate_format(:ctecli_rfc, ~r/^[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3}$/,
        message: "formato RFC inválido"
      )
    end

    defp put_default_fechaalta(changeset) do
      if is_nil(get_field(changeset, :ctecli_fechaalta)) do
        put_change(changeset, :ctecli_fechaalta, Date.utc_today())
      else
        changeset
      end
    end

    defp validate_direcciones(changeset) do
      direcciones = get_field(changeset, :direcciones, [])
      IO.inspect(direcciones, label: "Direcciones en validate_direcciones")

      # Verificar que haya al menos una dirección válida
      if Enum.empty?(direcciones) do
        add_error(changeset, :direcciones, "Debe agregar al menos una dirección")
      else
        changeset
      end
    end
  end

  # Función para generar código de cliente único
  defp generar_codigo_cliente do
    # Generar código aleatorio de 7 caracteres
    # 85% probabilidad de números, 15% de incluir una letra
    codigo = if :rand.uniform(100) > 15 do
      # Solo números (7 dígitos)
      # Usar timestamp parcial + aleatorio para mayor unicidad
      timestamp_part = System.system_time(:millisecond) |> rem(10000) |> Integer.to_string() |> String.pad_leading(4, "0")
      random_part = :rand.uniform(1000) |> Integer.to_string() |> String.pad_leading(3, "0")
      (timestamp_part <> random_part) |> String.slice(0..6)
    else
      # Con una letra en posición aleatoria (generalmente al inicio o final)
      timestamp_part = System.system_time(:millisecond) |> rem(100000) |> Integer.to_string() |> String.pad_leading(5, "0")
      random_digit = :rand.uniform(10) - 1 |> Integer.to_string()
      letra = Enum.random(?A..?Z) |> List.to_string()

      # 50% probabilidad de poner la letra al inicio o al final
      if :rand.uniform(2) == 1 do
        letra <> timestamp_part <> random_digit
      else
        timestamp_part <> random_digit <> letra
      end
      |> String.slice(0..6)
    end

    codigo
  end

  @impl true
  def mount(params, session, socket) do
    # Determinar si estamos en modo edición o creación
    cliente_id = Map.get(params, "id")

    # Crear o cargar cliente
    {cliente, page_title, current_path} = if cliente_id do
      # Modo edición: Cargar datos existentes desde la BD
      case Clientes.get_cliente_by_codigo(cliente_id) do
        {:ok, %{cliente: cliente_db, direcciones: direcciones_db}} ->
          # Convertir direcciones de la BD al formato del formulario
          direcciones_form = Enum.map(direcciones_db, fn dir ->
            %DireccionForm{
              ctedir_codigo_k: dir.ctedir_codigo_k,
              ctedir_responsable: dir.ctedir_responsable,
              ctedir_telefono: dir.ctedir_telefono,
              ctedir_calle: dir.ctedir_calle,
              ctedir_callenumext: dir.ctedir_callenumext,
              ctedir_callenumint: dir.ctedir_callenumint,
              ctedir_colonia: dir.ctedir_colonia,
              ctedir_cp: dir.ctedir_cp,
              ctedir_celular: dir.ctedir_celular,
              ctedir_mail: dir.ctedir_mail,
              mapedo_codigo_k: dir.mapedo_codigo_k,
              mapmun_codigo_k: dir.mapmun_codigo_k,
              maploc_codigo_k: dir.maploc_codigo_k,
              map_x: dir.map_x,
              map_y: dir.map_y,
              vtarut_codigo_k_pre: dir.vtarut_codigo_k_pre,
              vtarut_codigo_k_ent: dir.vtarut_codigo_k_ent,
              vtarut_codigo_k_cob: dir.vtarut_codigo_k_cob,
              vtarut_codigo_k_aut: dir.vtarut_codigo_k_aut,
              vtarut_codigo_k_simpre: dir.vtarut_codigo_k_simpre,
              vtarut_codigo_k_siment: dir.vtarut_codigo_k_siment,
              vtarut_codigo_k_simcob: dir.vtarut_codigo_k_simcob,
              vtarut_codigo_k_simaut: dir.vtarut_codigo_k_simaut,
              vtarut_codigo_k_sup: dir.vtarut_codigo_k_sup,
              ctepfr_codigo_k: dir.ctepfr_codigo_k,
              cteclu_codigo_k: dir.cteclu_codigo_k,
              ctezni_codigo_k: dir.ctezni_codigo_k,
              ctecor_codigo_k: dir.ctecor_codigo_k,
              condim_codigo_k: dir.condim_codigo_k,
              ctepaq_codigo_k: dir.ctepaq_codigo_k,
              ctevie_codigo_k: dir.ctevie_codigo_k,
              ctesvi_codigo_k: dir.ctesvi_codigo_k,
              satcp_codigo_k: dir.satcp_codigo_k,
              satcol_codigo_k: dir.satcol_codigo_k,
              c_estado_k: dir.c_estado_k,
              c_municipio_k: dir.c_municipio_k,
              c_localidad_k: dir.c_localidad_k,
              cfgest_codigo_k: dir.cfgest_codigo_k,
              ctedir_tipofis: to_string(dir.ctedir_tipofis || 0),
              ctedir_tipoent: to_string(dir.ctedir_tipoent || 0),
              ctedir_ivafrontera: to_string(dir.ctedir_ivafrontera || 0),
              ctedir_secuencia: dir.ctedir_secuencia || 0,
              ctedir_secuenciaent: dir.ctedir_secuenciaent || 0,
              ctedir_reqgeo: dir.ctedir_reqgeo || 0,
              ctedir_distancia: dir.ctedir_distancia || Decimal.new("1.0"),
              ctedir_novalidavencimiento: dir.ctedir_novalidavencimiento || 0,
              ctedir_edocred: dir.ctedir_edocred || 0,
              ctedir_diascredito: dir.ctedir_diascredito || 0,
              ctedir_limitecredi: dir.ctedir_limitecredi || Decimal.new("0"),
              ctedir_tipopago: dir.ctedir_tipopago || 0,
              ctedir_tipodefacr: dir.ctedir_tipodefacr || 0,
              s_maqedo: dir.s_maqedo || 0
            }
          end)

          # Si no hay direcciones, crear una por defecto
          direcciones_form = if Enum.empty?(direcciones_form) do
            [%DireccionForm{ctedir_codigo_k: "1"}]
          else
            direcciones_form
          end

          # Convertir cliente de BD al formato del formulario
          cliente = %ClienteForm{
            ctecli_codigo_k: cliente_db.ctecli_codigo_k,
            ctecli_razonsocial: cliente_db.ctecli_razonsocial,
            ctecli_dencomercia: cliente_db.ctecli_dencomercia,
            ctecli_rfc: cliente_db.ctecli_rfc || "XAXX010101000",
            ctecli_fechaalta: cliente_db.ctecli_fechaalta && NaiveDateTime.to_date(cliente_db.ctecli_fechaalta) || Date.utc_today(),
            ctecli_edocred: cliente_db.ctecli_edocred || 0,
            ctecli_diascredito: cliente_db.ctecli_diascredito || 0,
            ctecli_limitecredi: cliente_db.ctecli_limitecredi || Decimal.new("0.0"),
            ctecli_tipodefact: to_string(cliente_db.ctecli_tipodefact || 0),
            ctecli_tipofacdes: to_string(cliente_db.ctecli_tipofacdes || 0),
            ctecli_tipodefacr: (cliente_db.ctecli_tipodefacr || 0) == 1,
            ctecli_formapago: cliente_db.ctecli_formapago,
            ctecli_metodopago: cliente_db.ctecli_metodopago,
            ctecli_tipopago: cliente_db.ctecli_tipopago || "99",
            sat_uso_cfdi_k: cliente_db.sat_uso_cfdi_k || "G01",
            ctecli_fereceptormail: cliente_db.ctecli_fereceptormail,
            ctetpo_codigo_k: to_string(cliente_db.ctetpo_codigo_k || 1),
            ctecan_codigo_k: cliente_db.ctecan_codigo_k,
            ctesca_codigo_k: cliente_db.ctesca_codigo_k,
            ctereg_codigo_k: cliente_db.ctereg_codigo_k,
            systra_codigo_k: cliente_db.systra_codigo_k,
            ctepaq_codigo_k: cliente_db.ctepaq_codigo_k,
            facadd_codigo_k: cliente_db.facadd_codigo_k,
            ctepor_codigo_k: cliente_db.ctepor_codigo_k,
            condim_codigo_k: cliente_db.condim_codigo_k,
            ctecad_codigo_k: cliente_db.ctecad_codigo_k,
            cfgban_codigo_k: cliente_db.cfgban_codigo_k,
            faccom_codigo_k: cliente_db.faccom_codigo_k,
            facads_codigo_k: cliente_db.facads_codigo_k,
            cteseg_codigo_k: Map.get(cliente_db, :cteseg_codigo_k),
            cfgmon_codigo_k: cliente_db.cfgmon_codigo_k,
            catind_codigo_k: Map.get(cliente_db, :catind_codigo_k, "3"),
            catpfi_codigo_k: Map.get(cliente_db, :catpfi_codigo_k, "1"),
            ctecli_pais: cliente_db.ctecli_pais || "MEX",
            ctecli_generico: cliente_db.ctecli_generico || 0,
            ctecli_nocta: cliente_db.ctecli_nocta,
            ctecli_dscantimp: (cliente_db.ctecli_dscantimp || 1) == 1,
            ctecli_desglosaieps: (cliente_db.ctecli_desglosaieps || 0) == 1,
            ctecli_periodorefac: cliente_db.ctecli_periodorefac || 0,
            ctecli_cargaespecifica: cliente_db.ctecli_cargaespecifica || 0,
            ctecli_caducidadmin: cliente_db.ctecli_caducidadmin || 0,
            ctecli_ctlsanitario: cliente_db.ctecli_ctlsanitario || 0,
            ctecli_factablero: cliente_db.ctecli_factablero || 0,
            ctecli_aplicacanje: cliente_db.ctecli_aplicacanje || 0,
            ctecli_aplicadev: cliente_db.ctecli_aplicadev || 0,
            ctecli_desglosakit: (cliente_db.ctecli_desglosakit || 0) == 1,
            ctecli_facgrupo: cliente_db.ctecli_facgrupo || 0,
            ctecli_cxcliq: cliente_db.ctecli_cxcliq || 0,
            s_maqedo: cliente_db.s_maqedo || 0,
            direcciones: direcciones_form
          }

          {cliente, "Editar Cliente #{cliente_id}", "/admin/clientes/edit/#{cliente_id}"}

        {:error, :not_found} ->
          # Si no se encuentra el cliente, crear uno vacío con ese código
          cliente = %ClienteForm{
            ctecli_codigo_k: cliente_id,
            ctecli_fechaalta: Date.utc_today(),
            direcciones: [%DireccionForm{ctedir_codigo_k: "1"}]
          }
          {cliente, "Editar Cliente #{cliente_id} (No encontrado)", "/admin/clientes/edit/#{cliente_id}"}
      end
    else
      # Modo creación: nuevo cliente con código autogenerado
      codigo_generado = generar_codigo_cliente()
      cliente = %ClienteForm{
        ctecli_codigo_k: codigo_generado,
        ctecli_fechaalta: Date.utc_today(),
        direcciones: [%DireccionForm{ctedir_codigo_k: "1"}]
      }
      {cliente, "Nuevo Cliente", "/admin/clientes/new"}
    end

    form = to_form(ClienteForm.changeset(cliente, %{}))

    # Cargar catálogos desde la base de datos
    tipos_cliente = Catalogos.listar_tipos_cliente()
    cadenas = Catalogos.listar_cadenas()
    canales = Catalogos.listar_canales()
    regimenes = Catalogos.listar_regimenes()
    paquetes_servicio = Catalogos.listar_paquetes_servicio()
    transacciones = Catalogos.listar_transacciones()
    monedas = Catalogos.listar_monedas()
    estados = Catalogos.listar_estados()
    rutas = Catalogos.listar_rutas()
    usos_cfdi = Catalogos.listar_usos_cfdi()
    formas_pago = Catalogos.listar_formas_pago()
    metodos_pago = Catalogos.listar_metodos_pago()
    regimenes_fiscales = Catalogos.listar_regimenes_fiscales()

    # Obtener user_email de la sesión o usar un valor por defecto temporal
    user_email = session["user_email"] || "admin"

    {:ok,
     socket
     |> assign(:current_page, "clientes")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, user_email)
     |> assign(:current_path, current_path)
     |> assign(:form, form)
     |> assign(:page_title, page_title)
     |> assign(:current_tab, "basicos")
     |> assign(:cliente_id, cliente_id)
     |> assign(:tipos_cliente, tipos_cliente)
     |> assign(:cadenas, cadenas)
     |> assign(:canales, canales)
     |> assign(:subcanales, [])
     |> assign(:regimenes, regimenes)
     |> assign(:paquetes_servicio, paquetes_servicio)
     |> assign(:transacciones, transacciones)
     |> assign(:monedas, monedas)
     |> assign(:estados, estados)
     |> assign(:municipios, [])
     |> assign(:localidades, [])
     |> assign(:rutas, rutas)
     |> assign(:usos_cfdi, usos_cfdi)
     |> assign(:formas_pago, formas_pago)
     |> assign(:metodos_pago, metodos_pago)
     |> assign(:regimenes_fiscales, regimenes_fiscales)
     |> assign(:cfdi_tab, "cfdi_32")
     |> assign(:direccion_tab, "datos")
     |> assign(:complementos, [])
     |> assign(:paises, [{"México", "MEX"}])
     |> assign(:codigos_exportacion, [{"No aplica", "01"}, {"Definitiva", "02"}])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Get tab from params, default to "basicos"
    tab = Map.get(params, "tab", "basicos")
    # Validate tab
    valid_tabs = ["basicos", "clasificacion", "facturacion", "direcciones", "opcionales"]
    current_tab = if tab in valid_tabs, do: tab, else: "basicos"

    # Update current_path based on id if present
    cliente_id = Map.get(params, "id")
    current_path = if cliente_id do
      "/admin/clientes/edit/#{cliente_id}"
    else
      "/admin/clientes/new"
    end

    {:noreply, socket |> assign(:current_tab, current_tab) |> assign(:current_path, current_path)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"_target" => target, "cliente_form" => params} = event_params,
        socket
      ) do
    changeset =
      %ClienteForm{}
      |> ClienteForm.changeset(params)
      |> Map.put(:action, :validate)

    # Check if the change was on a estado or municipio field
    socket_with_form = assign(socket, :form, to_form(changeset))

    case target do
      # Root level fields (formulario nuevo)
      ["cliente_form", "mapedo_codigo_k"] ->
        # Estado changed, load municipios
        estado_codigo = Map.get(params, "mapedo_codigo_k")
        IO.inspect(estado_codigo, label: "Estado seleccionado (validate)")
        IO.inspect(target, label: "Target path")

        if estado_codigo && estado_codigo != "" do
          municipios = Catalogos.listar_municipios(estado_codigo)
          IO.inspect(length(municipios), label: "Municipios cargados (validate)")
          {:noreply, socket_with_form |> assign(:municipios, municipios) |> assign(:localidades, [])}
        else
          {:noreply, socket_with_form |> assign(:municipios, []) |> assign(:localidades, [])}
        end

      ["cliente_form", "mapmun_codigo_k"] ->
        # Municipio changed, load localidades
        estado_codigo = Map.get(params, "mapedo_codigo_k")
        municipio_codigo = Map.get(params, "mapmun_codigo_k")
        IO.inspect({estado_codigo, municipio_codigo}, label: "Estado y Municipio (validate)")

        if estado_codigo && municipio_codigo && estado_codigo != "" && municipio_codigo != "" do
          localidades = Catalogos.listar_localidades(estado_codigo, municipio_codigo)
          IO.inspect(length(localidades), label: "Localidades cargadas (validate)")
          {:noreply, assign(socket_with_form, :localidades, localidades)}
        else
          {:noreply, assign(socket_with_form, :localidades, [])}
        end

      # Nested direcciones (para formularios con múltiples direcciones)
      ["cliente_form", "direcciones", direccion_index, "mapedo_codigo_k"] ->
        # Estado changed, load municipios
        estado_codigo = get_in(params, ["direcciones", direccion_index, "mapedo_codigo_k"])

        if estado_codigo && estado_codigo != "" do
          municipios = Catalogos.listar_municipios(estado_codigo)
          {:noreply, socket_with_form |> assign(:municipios, municipios) |> assign(:localidades, [])}
        else
          {:noreply, socket_with_form |> assign(:municipios, []) |> assign(:localidades, [])}
        end

      ["cliente_form", "direcciones", direccion_index, "mapmun_codigo_k"] ->
        # Municipio changed, load localidades
        estado_codigo = get_in(params, ["direcciones", direccion_index, "mapedo_codigo_k"])
        municipio_codigo = get_in(params, ["direcciones", direccion_index, "mapmun_codigo_k"])

        if estado_codigo && municipio_codigo && estado_codigo != "" && municipio_codigo != "" do
          localidades = Catalogos.listar_localidades(estado_codigo, municipio_codigo)
          {:noreply, assign(socket_with_form, :localidades, localidades)}
        else
          {:noreply, assign(socket_with_form, :localidades, [])}
        end

      _ ->
        # Other field changed, just validate
        {:noreply, socket_with_form}
    end
  end

  # Fallback clause when _target is not present
  def handle_event("validate", %{"cliente_form" => params}, socket) do
    changeset =
      %ClienteForm{}
      |> ClienteForm.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"cliente_form" => params}, socket) do
    changeset = ClienteForm.changeset(%ClienteForm{}, params)

    # Determinar si estamos en modo edición o creación
    cliente_id = socket.assigns[:cliente_id]
    is_edit_mode = !is_nil(cliente_id)

    IO.inspect(if(is_edit_mode, do: "actualizar", else: "nuevo"), label: "MODO")

    case validate_and_extract(changeset) do
      {:ok, cliente_data} ->
        # Get user password for API authentication
        sysusr_codigo = socket.assigns[:current_user_email]
        # Verificar que el usuario esté autenticado
        if is_nil(sysusr_codigo) do
          {:noreply,
           socket
           |> put_flash(:error, "Sesión no válida. Por favor inicie sesión nuevamente.")
           |> assign(:form, to_form(changeset))}
        else
          password_query =
            from(u in User,
              where: u.sysusr_codigo_k == ^sysusr_codigo,
              select: u.sysusr_password
            )

          case Repo.one(password_query) do
            nil ->
              IO.inspect(:error, "No se pudo autenticar. Intente de nuevo.")

              {:noreply,
               socket
               |> put_flash(:error, "No se pudo autenticar. Intente de nuevo.")
               |> assign(:form, to_form(changeset))}

          password ->
            # Llamar al API según el modo (crear o actualizar)
            api_result = if is_edit_mode do
              ClientesApi.actualizar_cliente(cliente_data, password)
            else
              ClientesApi.crear_cliente(cliente_data, password)
            end

            action = if is_edit_mode, do: "actualizado", else: "creado"

            case api_result do
              {:ok, _response} ->
                IO.puts("Cliente #{action} exitosamente")

                {:noreply,
                 socket
                 |> put_flash(:info, "Cliente #{action} exitosamente")
                 |> push_event("navigate-after-flash", %{to: "/admin/clientes", delay: 3000})}

              {:error, {:http_error, status, body}} ->
                error_msg = extract_error_message(body, status)
                IO.puts("Error al #{action} cliente: #{error_msg}")

                {:noreply,
                 socket
                 |> put_flash(:error, "Error al #{action} cliente: #{error_msg}")
                 |> assign(:form, to_form(changeset))}

              {:error, reason} ->
                IO.inspect("Error al #{action} cliente")

                {:noreply,
                 socket
                 |> put_flash(:error, "Error de conexión: #{inspect(reason)}")
                 |> assign(:form, to_form(changeset))}
            end
          end
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("add_direccion", _params, socket) do
    # Obtener el changeset actual
    current_form = socket.assigns.form
    params = current_form.params || %{}

    # Obtener direcciones existentes
    direcciones = Map.get(params, "direcciones", [])

    # Calcular el siguiente código de dirección
    next_codigo = (length(direcciones) + 1) |> to_string()

    # Agregar nueva dirección
    new_direccion = %{
      "ctedir_codigo_k" => next_codigo,
      "ctedir_calle" => "",
      "ctedir_callenumext" => "",
      "ctedir_cp" => ""
    }

    updated_direcciones = direcciones ++ [new_direccion]
    updated_params = Map.put(params, "direcciones", updated_direcciones)

    # Crear nuevo changeset
    changeset =
      %ClienteForm{}
      |> ClienteForm.changeset(updated_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("remove_direccion", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    current_form = socket.assigns.form
    params = current_form.params || %{}

    # Obtener direcciones existentes
    direcciones = Map.get(params, "direcciones", [])

    # No permitir eliminar si solo hay una dirección
    if length(direcciones) <= 1 do
      {:noreply, put_flash(socket, :error, "Debe mantener al menos una dirección")}
    else
      # Eliminar la dirección en el índice especificado
      updated_direcciones = List.delete_at(direcciones, index)
      updated_params = Map.put(params, "direcciones", updated_direcciones)

      # Crear nuevo changeset
      changeset =
        %ClienteForm{}
        |> ClienteForm.changeset(updated_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("canal_change", %{"_target" => _target, "cliente_form" => params}, socket) do
    # Get canal_codigo from params
    canal_codigo = get_in(params, ["ctecan_codigo_k"])

    if canal_codigo && canal_codigo != "" do
      subcanales = Catalogos.listar_subcanales(canal_codigo)
      {:noreply, assign(socket, :subcanales, subcanales)}
    else
      {:noreply, assign(socket, :subcanales, [])}
    end
  end

  @impl true
  def handle_event("change_cfdi_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :cfdi_tab, tab)}
  end

  @impl true
  def handle_event("change_direccion_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :direccion_tab, tab)}
  end

  @impl true
  def handle_event("update_coordinates", %{"lat" => lat, "lng" => lng}, socket) do
    # Este evento se llama desde el hook de JavaScript cuando se actualiza el mapa
    {:noreply, socket}
  end

  @impl true
  def handle_event("update_map_from_coords", _params, socket) do
    # Este evento se llama cuando el usuario actualiza manualmente las coordenadas
    {:noreply, socket}
  end

  @impl true
  def handle_event("cp_blur", %{"codigo_postal" => cp, "direccion_index" => index_str}, socket) do
    if String.match?(cp, ~r/^\d{5}$/) do
      case Catalogos.buscar_por_cp(cp) do
        {:ok, ubicacion} ->
          municipios = Catalogos.listar_municipios(ubicacion.estado_codigo)

          localidades =
            Catalogos.listar_localidades(ubicacion.estado_codigo, ubicacion.municipio_codigo)

          current_form = socket.assigns.form
          params = current_form.params || %{}
          direcciones = Map.get(params, "direcciones", [])
          index = String.to_integer(index_str)

          updated_direccion =
            Enum.at(direcciones, index)
            |> Map.put("mapedo_codigo_k", ubicacion.estado_codigo)
            |> Map.put("mapmun_codigo_k", ubicacion.municipio_codigo)
            |> Map.put("maploc_codigo_k", ubicacion.localidad_codigo)

          updated_direcciones = List.replace_at(direcciones, index, updated_direccion)
          updated_params = Map.put(params, "direcciones", updated_direcciones)

          changeset =
            %ClienteForm{}
            |> ClienteForm.changeset(updated_params)
            |> Map.put(:action, :validate)

          {:noreply,
           socket
           |> assign(:form, to_form(changeset))
           |> assign(:municipios, municipios)
           |> assign(:localidades, localidades)
           |> put_flash(
             :info,
             "Ubicación encontrada: #{ubicacion.estado_nombre}, #{ubicacion.municipio_nombre}"
           )}

        {:error, :not_found} ->
          {:noreply, put_flash(socket, :error, "No se encontró ubicación para el CP: #{cp}")}

        {:error, :invalid_cp} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    path = if socket.assigns[:cliente_id] do
      ~p"/admin/clientes/edit/#{socket.assigns.cliente_id}/#{tab}"
    else
      ~p"/admin/clientes/new/#{tab}"
    end
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    case id do
      "toggle_sidebar" ->
        {:noreply, Phoenix.Component.update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

      "clientes" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/clientes")}

      _ ->
        {:noreply, socket}
    end
  end

  defp validate_and_extract(changeset) do
    if changeset.valid? do
      cliente = Ecto.Changeset.apply_changes(changeset)
      IO.inspect(cliente.direcciones, label: "Direcciones en validate_and_extract")
      {:ok, cliente}
    else
      {:error, changeset}
    end
  end

  defp extract_error_message(body, status) when is_list(body) do
[error] = body
cond do
Map.has_key?(error, "Respuesta") -> error["Respuesta"]
true -> "Error HTTP #{status}"
    end
  end

  defp extract_error_message(_body, status), do: "Error HTTP #{status}"
end
