# Inkash

![CI](https://github.com/saulecch/inkash/actions/workflows/ci.yml/badge.svg)

App de finanzas personales en Flutter — proyecto de clase de Programación de
Dispositivos Móviles (UMES 2026).

## Cómo correrla

```bash
flutter pub get
flutter run            # Android, iOS o macOS. NO Chrome: sqflite no soporta Web.
flutter test           # pruebas (SQLite corre en la compu con sqflite_common_ffi)
```

## Qué hace
- **Bienvenida** (la primera vez): nombre, límite mensual y saldos de hoy.
- **Inicio**: cuánto te queda del mes frente a tu límite, saldo de cuentas, metas activas,
  tipo de cambio y últimos movimientos (tocar uno = editarlo).
- **Presupuesto**: límite mensual por categoría con avance y resumen.
- **(+)**: registrar gasto o ingreso con categoría (o crear una nueva) y cuenta.
- **Historial**: por mes y categoría; tocar para editar, deslizar para borrar con *Deshacer*.
- **Ajustes**: perfil, límite mensual, cuentas (con saldo inicial), categorías
  (crear, archivar) y borrar los datos.
- **Metas de ahorro**: desde la tarjeta del Inicio; crear, editar, aportar y retirar.

Diseño: tokens y componentes en [`docs/diseno.md`](docs/diseno.md).

## Publicar
Ver [`docs/publicacion/firma.md`](docs/publicacion/firma.md) y
[`docs/tienda/checklist-play.md`](docs/tienda/checklist-play.md). En resumen:
subir `version` en el pubspec y `git push origin vX.Y.Z`.

## Arquitectura

```
lib/
  core/              base de datos, formato de dinero y fechas
  features/
    home/
      domain/        entidades (Movimiento, NuevoMovimiento)
      data/          datasource (SQL) -> repository
      presentation/  controller (Riverpod AsyncNotifier) + widgets
    tipo_cambio/     API remota + caché SQLite (mismas capas)
    historial/ cuentas/ categorias/ presupuesto/ metas/ ajustes/
    bienvenida/ navegacion/
  core/ui/           componentes del sistema de diseño
```

Decisiones documentadas en [`docs/adr/`](docs/adr/README.md).
Cómo colaborar: [`CONTRIBUTING.md`](CONTRIBUTING.md). Uso de IA: [`docs/bitacora-ia.md`](docs/bitacora-ia.md).

## Base de datos local

La aplicación abre `inkash.db` (versión 7, ver `AppDatabase.migraciones`) la primera vez que un provider la necesita.
`AppDatabase.instance.database` entrega la conexión compartida de sqflite.

- `categorias`: `id` autoincremental, `nombre` único e `icono`.
- `movimientos`: `id` de texto, `titulo`, `monto_centavos`, `fecha`,
  `categoria_id` obligatorio. El medio de pago queda pendiente de su propia tabla.
- Una categoría tiene muchos movimientos. La clave foránea se activa en cada
  apertura y bloquea la eliminación de categorías con movimientos asociados.
- `monto_centavos` guarda el signo: positivo para ingresos y negativo para gastos.
  No se almacena `es_ingreso`; el saldo se calcula sumando los montos.
- `fecha` es un `INTEGER` con el timestamp Unix en milisegundos, que conserva
  fecha y hora. Guardar con `DateTime.millisecondsSinceEpoch` y leer con
  `DateTime.fromMillisecondsSinceEpoch(valor, isUtc: true)`. Convertir a hora
  local con `.toLocal()` al mostrarla. No almacena la zona horaria original.
- El nombre y el icono provienen de la categoría.

Las tablas se crean vacías. El dashboard todavía usa sus datos de ejemplo en
memoria; su conexión al almacenamiento será un paso posterior.
La inicialización usa sqflite para Android, iOS y macOS.

Ejecutar `flutter test` para comprobar persistencia e integridad referencial.
- `cache_tipo_cambio` (v2): último tipo de cambio USD→GTQ recibido, para modo sin conexión.
