# Campos Visibles en Formulario de Clientes

Este documento lista todos los campos visibles en el formulario de alta de clientes, organizados por sección.

## 1. DATOS BÁSICOS
- **ctecli_codigo_k** * - Código Cliente (NOT NULL)
- **ctecli_rfc** - RFC
- **ctecli_razonsocial** - Razón Social
- **ctecli_dencomercia** - Nombre Comercial
- **ctecli_fereceptormail** - Email para facturación
- **ctecli_nocta** - Número de Cuenta

## 2. INFORMACIÓN DE CRÉDITO
- **ctecli_diascredito** - Días de Crédito (default: 0)
- **ctecli_limitecredi** - Límite de Crédito (default: 0.00)
- **ctecli_edocred** - Estado de Crédito (0=Sin crédito, 1=Crédito activo)

## 3. CLASIFICACIÓN (Catálogos Obligatorios NOT NULL)
- **ctetpo_codigo_k** * - Tipo de Cliente (FK → CTE_TIPO)
- **ctecan_codigo_k** * - Canal (FK → CTE_SUBCANAL)
- **ctesca_codigo_k** * - Subcanal (FK → CTE_SUBCANAL, cascada desde Canal)
- **ctereg_codigo_k** * - Régimen (FK → CTE_REGIMEN)
- **systra_codigo_k** * - Transacción (FK → SYS_TRANSAC)
- **cfgmon_codigo_k** - Moneda (FK → CFG_MONEDA)

## 4. FACTURACIÓN (Catálogos SAT)
- **ctecli_formapago** - Forma de Pago SAT (FK → CFG_FORMAPAGO_SAT)
- **ctecli_metodopago** - Método de Pago SAT (PUE/PPD)
- **sat_uso_cfdi_k** - Uso de CFDI (FK → CFG_USOCFDISAT)
- **cfgreg_codigo_k** - Régimen Fiscal SAT (FK → CFG_REGIMENFISCAL_SAT, default: "601")

## 5. CATÁLOGOS OPCIONALES (Foreign Keys)
Campos adicionales con referencias a catálogos del sistema:

- **cfgmon_codigo_k** - Moneda (FK → CFG_MONEDA) - SELECT
- **ctepaq_codigo_k** - Paquete (FK → CTE_PAQUETE) - Texto
- **facadd_codigo_k** - Adenda (FK → FAC_ADENDA) - Texto
- **ctepor_codigo_k** - Portafolio (FK → CTE_PORTAFOLIO) - Texto
- **condim_codigo_k** - Dimensión (FK → CON_DIMENSION) - Texto
- **ctecad_codigo_k** - Cadena (FK → CTE_CADENA) - Texto
- **cfgban_codigo_k** - Banco (FK → CFG_BANCO) - Texto
- **sysemp_codigo_k** - Empresa (FK → SYS_EMPRESA) - Texto
- **faccom_codigo_k** - Comprobante (FK → FAC_COMPROBANTE) - Texto
- **facads_codigo_k** - Adenda SAT (FK → FAC_ADENDA_SAT) - Texto
- **cteseg_codigo_k** - Segmento (FK → CTE_SEGMENTO) - Texto
- **catind_codigo_k** - Industria (FK → CAT_INDUSTRIA) - Texto
- **catpfi_codigo_k** - Perfil (FK → CAT_PERFIL) - Texto
- **satexp_codigo_k** - Exportación SAT (default: "01")
- **ctecli_pais** - País (default: "MEX")

## 6. DIRECCIONES (Múltiples, Mínimo 1)

Cada dirección tiene los siguientes campos:

### Identificación
- **ctedir_codigo_k** * - Código de dirección (auto-generado) (NOT NULL)

### Dirección Física
- **ctedir_calle** * - Calle (NOT NULL)
- **ctedir_callenumext** * - Número Exterior (NOT NULL)
- **ctedir_callenumint** - Número Interior
- **ctedir_colonia** - Colonia
- **ctedir_cp** * - Código Postal (NOT NULL, 5 dígitos, con auto-completado)

### Ubicación Geográfica (Cascada)
- **mapedo_codigo_k** * - Estado (NOT NULL, FK → MAP_ESTADO) - SELECT
- **mapmun_codigo_k** * - Municipio (NOT NULL, FK → MAP_MUNICIPIO) - SELECT cascada
- **maploc_codigo_k** * - Localidad (NOT NULL, FK → MAP_LOCALIDAD) - SELECT cascada

### Contacto
- **ctedir_responsable** - Responsable
- **ctedir_telefono** - Teléfono
- **ctedir_celular** - Celular
- **ctedir_mail** - Email

### Rutas (FK → VTA_RUTA)
- **vtarut_codigo_k_pre** - Ruta Preventa - SELECT
- **vtarut_codigo_k_ent** - Ruta Entrega - SELECT
- **vtarut_codigo_k_cob** - Ruta Cobranza - SELECT
- **vtarut_codigo_k_aut** - Ruta Autoventa - SELECT

## CAMPOS OCULTOS/AUTO-GENERADOS

Los siguientes campos tienen valores por defecto y no se muestran en el formulario:

### Fechas
- **ctecli_fechaalta** - Fecha de Alta (auto: NaiveDateTime.utc_now())

### Flags (Valores por defecto según spec)
- **ctecli_generico** - Es genérico (default: 0)
- **ctecli_dscantimp** - Descuento cantidad impuesto (default: 1)
- **ctecli_desglosaieps** - Desglosar IEPS (default: 0)
- **ctecli_periodorefac** - Periodo refacturación (default: 0)
- **ctecli_cargaespecifica** - Carga específica (default: 0)
- **ctecli_caducidadmin** - Caducidad mínima (default: 0)
- **ctecli_ctlsanitario** - Control sanitario (default: 0)
- **ctecli_factablero** - Factura tablero (default: 0)
- **ctecli_aplicacanje** - Aplica canje (default: 0)
- **ctecli_aplicadev** - Aplica devolución (default: 0)
- **ctecli_desglosakit** - Desglosa kit (default: 0)
- **ctecli_facgrupo** - Factura grupo (default: 0)
- **ctecli_timbracb** - Timbra CB (default: 0)
- **ctecli_novalidavencimiento** - No valida vencimiento (default: 0)
- **ctecli_cfdi_ver** - Versión CFDI (default: 0)
- **ctecli_aplicaregalo** - Aplica regalo (default: 0)
- **ctecli_noaceptafracciones** - No acepta fracciones (default: 0)
- **ctecli_cxcliq** - CxC liquidación (default: 0)

### Tipos de Facturación
- **ctecli_tipodefact** - Tipo de factura (default: 0)
- **ctecli_tipofacdes** - Tipo factura descuento (default: 0)
- **ctecli_tipodefacr** - Tipo de factura R (default: 0)
- **ctecli_tipopago** - Tipo de pago (default: "99")

### Sistema
- **s_maqedo** - Máquina edición (default: 0)

## FUNCIONALIDADES ESPECIALES

### Selects Dinámicos con Cascada
1. **Canal → Subcanal**: Al seleccionar Canal, se cargan los Subcanales correspondientes
2. **Estado → Municipio → Localidad**: Cascada de ubicación geográfica

### Auto-completado por Código Postal
Al ingresar un CP de 5 dígitos y salir del campo (blur):
- Busca la ubicación en MAP_LOCALIDAD
- Auto-completa: Estado, Municipio y Localidad
- Muestra mensaje de confirmación con la ubicación encontrada

### Múltiples Direcciones
- Botón "Agregar Dirección" para añadir más direcciones
- Botón "Eliminar" en cada dirección (mínimo 1 requerido)
- Validación de al menos una dirección

## LEYENDA
- `*` = Campo obligatorio (NOT NULL)
- `FK` = Foreign Key (referencia a catálogo)
- `default: X` = Valor por defecto
