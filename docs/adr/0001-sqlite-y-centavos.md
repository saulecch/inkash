# ADR-0001: Persistencia local con SQLite y dinero en centavos enteros

- Estado: Aceptado
- Fecha: 2026-09-17 (tablas) · 2026-10-15 (lectura/escritura conectadas)
- Commits: `5b32e14`, `s14-01-guardar`, `s14-02-leer-async`

## Contexto
Inkash registra gastos e ingresos. Si el usuario cierra la app, los datos deben
seguir ahí. Funciona sin cuenta ni servidor: los datos son del teléfono.
Las consultas que necesitamos son relacionales (movimientos ↔ categorías,
sumas por categoría, orden por fecha).

## Decisión
- Usaremos **SQLite** vía `sqflite`, con una sola clase `AppDatabase` que abre
  la base una vez y la comparte.
- Solo los *datasources* escriben SQL. Widgets y controladores nunca.
- El dinero se guarda como **entero en centavos** (`monto_centavos INTEGER`).
  En SQL el gasto es negativo, para que `SUM(monto_centavos)` sea el saldo.
  En el dominio el monto es positivo + `esIngreso`.
- Las fechas se guardan como **epoch en milisegundos** (`INTEGER`).

## Alternativas consideradas
- **SharedPreferences**: sirve para ajustes, no para listas que se filtran y suman.
- **Hive / Isar**: más rápidos de empezar, pero sin SQL ni llaves foráneas, y el
  curso quiere que se entienda el modelo relacional.
- **Firebase / backend**: requiere cuenta e internet; el MVP no lo necesita.
- **`double` para dinero**: `0.1 + 0.2 != 0.3`. Descartado.

## Consecuencias
- ➕ Los datos sobreviven al cierre de la app; hay integridad con `FOREIGN KEY`.
- ➕ Probamos con `sqflite_common_ffi` en la computadora, sin emulador.
- ➖ `sqflite` **no funciona en Web**: el equipo prueba en Android/iOS/macOS.
- ➖ Cambiar el esquema exige **migraciones** (`version` + `onUpgrade`), ver ADR-0003.
- ➖ Sin sincronización entre dispositivos. Si se pide, se escribe un ADR nuevo.
