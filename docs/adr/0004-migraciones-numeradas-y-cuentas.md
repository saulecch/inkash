# ADR-0004: Migraciones numeradas y cuentas con "Efectivo" por defecto

- Estado: Aceptado
- Fecha: 2026-10-29
- Commit: `s16-01-cuentas`

## Contexto
Hasta la v2 el esquema se escribía dos veces: completo en `onCreate` y por
partes en `onUpgrade`. Con cada versión nueva crece el riesgo de que un
usuario nuevo y uno actualizado terminen con bases distintas.
Además, el home promete "Cuentas" y los movimientos no sabían de qué cuenta salían.

## Decisión
- El esquema es un mapa `versión -> migración` (`AppDatabase.migraciones`).
  `onCreate` aplica de la 1 a la última; `onUpgrade`, solo las que faltan.
- Una migración publicada **no se edita**: los cambios van en una nueva.
- v3 crea `cuentas` con Efectivo, Banco y Tarjeta, y agrega
  `movimientos.cuenta_id`. Los movimientos existentes quedan en **Efectivo**.
- El saldo de una cuenta = saldo inicial + `SUM(monto_centavos)`, con
  `LEFT JOIN` para que las cuentas sin movimientos también aparezcan.

## Alternativas consideradas
- **Dejar `cuenta_id` en NULL para datos viejos**: la UI tendría que manejar
  "sin cuenta" en todas partes. Descartado.
- **Recrear la tabla `movimientos` con `cuenta_id NOT NULL`** (crear nueva,
  copiar, borrar vieja): más correcto en SQL, pero riesgoso para el curso.
  Candidato si algún día se necesita la restricción.

## Consecuencias
- ➕ Prueba automática: esquema de instalación nueva == esquema actualizado.
- ➖ `cuenta_id` es nullable a nivel SQL; la app siempre lo envía.
- ➖ Asumir "Efectivo" puede ser falso para algunos usuarios; podrán editarlo
  cuando exista la edición de movimientos.
