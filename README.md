# inkash

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Base de datos local

La aplicación abre `inkash.db` (versión 1) antes de iniciar la interfaz.
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
