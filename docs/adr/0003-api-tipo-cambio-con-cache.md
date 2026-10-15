# ADR-0003: Datos remotos — red primero, caché local si falla

- Estado: Aceptado
- Fecha: 2026-10-15
- Commit: `s14-03-api`

## Contexto
Los usuarios de las entrevistas pagan suscripciones y compras en dólares.
Mostrar el tipo de cambio del día ayuda a decidir. El dato viene de internet,
y en Guatemala la conexión móvil es intermitente (bus, interior del país).

## Decisión
- Consumiremos `https://open.er-api.com/v6/latest/USD` (gratuita, sin API key)
  con `package:http`, **timeout de 5 s** y un `http.Client` inyectable.
- Toda falla se traduce a `TipoCambioException` con un mensaje para humanos:
  sin red · timeout · status ≠ 200 · JSON inesperado.
- La tasa se convierte a **entero (diezmilésimas)** en la frontera.
- **Red primero, caché si falla**: cada respuesta buena se guarda en la tabla
  `cache_tipo_cambio`. Sin red, mostramos el último dato **y lo decimos**
  ("Sin conexión · último dato 14/10 18:05").
- La tabla llega con la **versión 2** de la base (`onUpgrade`), sin borrar datos v1.
- Permiso `INTERNET` en el `AndroidManifest.xml` principal (no solo en debug).

## Alternativas consideradas
- **Banguat (tipo de cambio oficial)**: el servicio es SOAP/XML; más trabajo
  para la clase. Candidato a reemplazo en un ADR futuro.
- **Sin caché**: con mala señal el usuario vería solo errores.
- **Caché primero, red después (stale-while-revalidate)**: mejor UX pero más
  complejo; lo dejamos como mejora.

## Consecuencias
- ➕ La tarjeta tiene sus propios estados: si la API cae, el dashboard sigue.
- ➕ Pruebas sin internet con `MockClient`.
- ➖ Dependemos de un tercero gratuito (límite de peticiones, puede cambiar el JSON).
- ➖ El dato en caché puede tener horas; por eso se muestra la hora y en otro color.
- Señal de error: si en la telemetría (S15) vemos muchos `desdeCache`, revisar el proveedor.
