# Todos los Campos del JSON - Cliente y Direcciones

## 📊 CAMPOS DEL CLIENTE (68 campos)

### ✅ Campos YA implementados en clientes_api.ex (47 campos):

1. `CTECLI_CODIGO_K` - Código Cliente ✅
2. `CTECLI_RAZONSOCIAL` - Razón Social ✅
3. `CTECLI_DENCOMERCIA` - Denominación Comercial ✅
4. `CTECLI_RFC` - RFC ✅
5. `CTECLI_FECHAALTA` - Fecha de Alta ✅
6. `CTECLI_EDOCRED` - Estado de Crédito ✅
7. `CTECLI_DIASCREDITO` - Días de Crédito ✅
8. `CTECLI_LIMITECREDI` - Límite de Crédito ✅
9. `CTECLI_TIPODEFACT` - Tipo de Factura ✅
10. `CTECLI_TIPOFACDES` - Tipo Factura Descuento ✅
11. `CTECLI_TIPOPAGO` - Tipo de Pago ✅
12. `CTETPO_CODIGO_K` - Tipo de Cliente ✅
13. `CTECAN_CODIGO_K` - Canal ✅
14. `CTESCA_CODIGO_K` - Subcanal ✅
15. `CTEPAQ_CODIGO_K` - Paquete ✅
16. `CTEREG_CODIGO_K` - Régimen ✅
17. `CTECAD_CODIGO_K` - Cadena ✅
18. `CTECLI_GENERICO` - Es Genérico ✅
19. `CFGMON_CODIGO_K` - Moneda ✅
20. `SYSTRA_CODIGO_K` - Transacción ✅
21. `FACADD_CODIGO_K` - Adenda ✅
22. `CTECLI_FERECEPTORMAIL` - Email Receptor Facturación ✅
23. `CTEPOR_CODIGO_K` - Portafolio ✅
24. `CTECLI_TIPODEFACR` - Tipo de Factura R ✅
25. `CONDIM_CODIGO_K` - Dimensión ✅
26. `CTECLI_CXCLIQ` - CxC Liquidación ✅
27. `CTECLI_NOCTA` - Número de Cuenta ✅
28. `CTECLI_DSCANTIMP` - Descuento Cantidad Impuesto ✅
29. `CTECLI_DESGLOSAIEPS` - Desglosa IEPS ✅
30. `CTECLI_PERIODOREFAC` - Periodo Refacturación ✅
31. `CFGBAN_CODIGO_K` - Banco ✅
32. `CTECLI_CARGAESPECIFICA` - Carga Específica ✅
33. `CTECLI_CADUCIDADMIN` - Caducidad Mínima ✅
34. `CTECLI_CTLSANITARIO` - Control Sanitario ✅
35. `CTECLI_FORMAPAGO` - Forma de Pago ✅
36. `CTECLI_METODOPAGO` - Método de Pago ✅
37. `CTECLI_PAIS` - País ✅
38. `CTECLI_FACTABLERO` - Factura Tablero ✅
39. `SAT_USO_CFDI_K` - Uso de CFDI ✅
40. `CTECLI_APLICACANJE` - Aplica Canje ✅
41. `CTECLI_APLICADEV` - Aplica Devolución ✅
42. `CTECLI_DESGLOSAKIT` - Desglosa Kit ✅
43. `FACCOM_CODIGO_K` - Comprobante ✅
44. `CTECLI_FACGRUPO` - Factura Grupo ✅
45. `FACADS_CODIGO_K` - Adenda SAT ✅
46. `CTECLI_TIMBRACB` - Timbra CB ✅
47. `SYSEMP_CODIGO_K` - Empresa ✅
48. `CTECLI_NOVALIDAVENCIMIENTO` - No Valida Vencimiento ✅
49. `SATEXP_CODIGO_K` - Exportación SAT ✅
50. `CFGREG_CODIGO_K` - Régimen Fiscal SAT ✅
51. `CTECLI_CFDI_VER` - Versión CFDI ✅
52. `CTECLI_APLICAREGALO` - Aplica Regalo ✅
53. `CTECLI_NOACEPTAFRACCIONES` - No Acepta Fracciones ✅
54. `CTESEG_CODIGO_K` - Segmento ✅
55. `CATIND_CODIGO_K` - Industria ✅
56. `CATPFI_CODIGO_K` - Perfil ✅
57. `S_MAQEDO` - Máquina de Edición ✅

### ❌ Campos FALTANTES (21 campos nuevos):

1. `CTECLI_FECHABAJA` - Fecha de Baja
2. `CTECLI_CAUSABAJA` - Causa de Baja
3. `CTECLI_CREDITOOBS` - Observaciones de Crédito
4. `CTECLI_OBSERVACIONES` - Observaciones Generales
5. `CTECLI_FERECEPTOR` - Fecha Receptor
6. `CTECLI_CONTACTO` - Contacto
7. `CTECLI_REGTRIB` - Registro Tributario
8. `CTECLI_COMPLEMENTO` - Complemento
9. `CTECLI_COMPATIBILIDAD` - Compatibilidad
10. `CTECLI_NOMBRE` - Nombre
11. `CTECLI_PRVPORTEOFAC` - Proveedor Porteo Factura
12. `CTECLI_ECOMMERCE` - E-commerce

---

## 📍 CAMPOS DE DIRECCIÓN (88 campos)

### ✅ Campos YA implementados en clientes_api.ex (22 campos):

1. `CTEDIR_CODIGO_K` - Código de Dirección ✅
2. `CTEDIR_CALLE` - Calle ✅
3. `CTEDIR_CALLENUMEXT` - Número Exterior ✅
4. `CTEDIR_CALLENUMINT` - Número Interior ✅
5. `CTEDIR_COLONIA` - Colonia ✅
6. `CTEDIR_CP` - Código Postal ✅
7. `MAPEDO_CODIGO_K` - Estado ✅
8. `MAPMUN_CODIGO_K` - Municipio ✅
9. `MAPLOC_CODIGO_K` - Localidad ✅
10. `MAP_X` - Coordenada X ✅
11. `MAP_Y` - Coordenada Y ✅
12. `CTEDIR_RESPONSABLE` - Responsable ✅
13. `CTEDIR_TELEFONO` - Teléfono ✅
14. `CTEDIR_CELULAR` - Celular ✅
15. `CTEDIR_MAIL` - Email ✅
16. `VTARUT_CODIGO_K_PRE` - Ruta Preventa ✅
17. `VTARUT_CODIGO_K_ENT` - Ruta Entrega ✅
18. `VTARUT_CODIGO_K_COB` - Ruta Cobranza ✅
19. `VTARUT_CODIGO_K_AUT` - Ruta Autoventa ✅
20. `CTEPFR_CODIGO_K` - Perfil Frecuencia ✅
21. `CTECLU_CODIGO_K` - Cluster ✅
22. `CTEZNI_CODIGO_K` - Zona ✅

### ❌ Campos FALTANTES en direcciones (66 campos nuevos):

1. `CTECLI_CODIGO_K` - Código Cliente (FK)
2. `CTECLI_RAZONSOCIAL` - Razón Social (duplicado)
3. `CTECLI_DENCOMERCIA` - Denominación Comercial (duplicado)
4. `CTEDIR_TIPOFIS` - Tipo Fiscal
5. `CTEDIR_TIPOENT` - Tipo Entrega
6. `CTEDIR_CALLEENTRE1` - Calle Entre 1
7. `CTEDIR_CALLEENTRE2` - Calle Entre 2
8. `CTECOR_CODIGO_K` - Corredor
9. `CTEDIR_OBSERVACIONES` - Observaciones
10. `CTEDIR_IVAFRONTERA` - IVA Frontera
11. `SYSTRA_CODIGO_K` - Transacción
12. `CTEDIR_SECUENCIA` - Secuencia
13. `CTEDIR_SECUENCIAENT` - Secuencia Entrega
14. `CTEDIR_GEOUBICACION` - Geolocalización
15. `VTARUT_CODIGO_K_SIMPRE` - Ruta Sim Preventa
16. `VTARUT_CODIGO_K_SIMENT` - Ruta Sim Entrega
17. `VTARUT_CODIGO_K_SIMCOB` - Ruta Sim Cobranza
18. `VTARUT_CODIGO_K_SIMAUT` - Ruta Sim Autoventa
19. `CONDIM_CODIGO_K` - Dimensión
20. `CTEDIR_REQGEO` - Requerimiento Geo
21. `CTEDIR_GUIDREF` - GUID Referencia
22. `CTEPAQ_CODIGO_K` - Paquete
23. `VTARUT_CODIGO_K_SUP` - Ruta Supervisor
24. `CTEDIR_SECUENCIALU` - Secuencia Lunes
25. `CTEDIR_SECUENCIAMA` - Secuencia Martes
26. `CTEDIR_SECUENCIAMI` - Secuencia Miércoles
27. `CTEDIR_SECUENCIAJU` - Secuencia Jueves
28. `CTEDIR_SECUENCIAVI` - Secuencia Viernes
29. `CTEDIR_SECUENCIASA` - Secuencia Sábado
30. `CTEDIR_SECUENCIADO` - Secuencia Domingo
31. `CTEDIR_SECUENCIAENTLU` - Secuencia Entrega Lunes
32. `CTEDIR_SECUENCIAENTMA` - Secuencia Entrega Martes
33. `CTEDIR_SECUENCIAENTMI` - Secuencia Entrega Miércoles
34. `CTEDIR_SECUENCIAENTJU` - Secuencia Entrega Jueves
35. `CTEDIR_SECUENCIAENTVI` - Secuencia Entrega Viernes
36. `CTEDIR_SECUENCIAENTSA` - Secuencia Entrega Sábado
37. `CTEDIR_SECUENCIAENTDO` - Secuencia Entrega Domingo
38. `CTEDIR_CODIGOPOSTAL` - Código Postal (duplicado)
39. `CTEDIR_MUNICIPIO` - Municipio Texto
40. `CTEDIR_ESTADO` - Estado Texto
41. `CTEDIR_LOCALIDAD` - Localidad Texto
42. `CTEVIE_CODIGO_K` - Vía
43. `CTESVI_CODIGO_K` - Sub Vía
44. `SATCOL_CODIGO_K` - Colonia SAT
45. `CTEDIR_DISTANCIA` - Distancia
46. `CTEDIR_NOVALIDAVENCIMIENTO` - No Valida Vencimiento
47. `CTEDIR_EDOCRED` - Estado Crédito
48. `CTEDIR_DIASCREDITO` - Días Crédito
49. `CTEDIR_LIMITECREDI` - Límite Crédito
50. `CTEDIR_TIPOPAGO` - Tipo Pago
51. `CTEDIR_CREDITOOBS` - Observaciones Crédito
52. `CTEDIR_TIPODEFACR` - Tipo Factura R
53. `CFGEST_CODIGO_K` - Estado (Config)
54. `CTEDIR_TELADICIONAL` - Teléfono Adicional
55. `CTEDIR_MAILADICIONAL` - Mail Adicional
56. `C_LOCALIDAD_K` - Localidad K
57. `C_MUNICIPIO_K` - Municipio K
58. `C_ESTADO_K` - Estado K
59. `SATCP_CODIGO_K` - Código Postal SAT
60. `CTEDIR_MAILDICIONAL` - Mail Dicional (¿typo?)

---

## 📊 RESUMEN

### Cliente:
- **Total**: 68 campos
- **Implementados**: 57 campos ✅
- **Faltantes**: 11 campos ❌

### Dirección:
- **Total**: 88 campos
- **Implementados**: 22 campos ✅
- **Faltantes**: 66 campos ❌

### Gran Total:
- **Campos totales**: 156 campos
- **Implementados**: 79 campos (50.6%)
- **Faltantes**: 77 campos (49.4%)

---

## 🎯 CAMPOS CRÍTICOS FALTANTES

### Cliente (11 campos):
1. `CTECLI_FECHABAJA` - Puede ser importante para auditoría
2. `CTECLI_CAUSABAJA` - Importante para historial
3. `CTECLI_CREDITOOBS` - Observaciones críticas de crédito
4. `CTECLI_OBSERVACIONES` - Notas generales
5. `CTECLI_CONTACTO` - Persona de contacto
6. `CTECLI_NOMBRE` - Nombre adicional
7. Los demás son campos adicionales menos críticos

### Dirección (66 campos):
**Críticos (20 campos)**:
- `CTEDIR_TIPOFIS` / `CTEDIR_TIPOENT` - Tipos importantes
- `CTEDIR_CALLEENTRE1` / `CTEDIR_CALLEENTRE2` - Referencias de ubicación
- `CTEDIR_OBSERVACIONES` - Notas de dirección
- `CTEDIR_IVAFRONTERA` - Importante para cálculos fiscales
- Secuencias de visita (14 campos) - Importantes para ruteo
- Campos de crédito por dirección (5 campos)

**Opcionales (46 campos)**:
- Campos de simulación de rutas (4 campos)
- Campos SAT adicionales (2 campos)
- Campos duplicados de texto (4 campos)
- Campos auxiliares y de configuración
