# ADR-0002: Estado asíncrono con Riverpod `AsyncNotifier`

- Estado: Aceptado (reemplaza el `Provider` síncrono de S09)
- Fecha: 2026-10-15
- Commit: `s14-02-leer-async`

## Contexto
En S09 el controlador leía una lista en memoria: síncrono, nunca fallaba.
Al leer de SQLite (y luego de internet) aparecen tres realidades nuevas:
**tarda**, **puede fallar** y **puede estar vacío**. Si la pantalla no las
modela, el usuario ve una pantalla congelada o un error rojo.

## Decisión
- Usaremos `flutter_riverpod` con `ProviderScope` en la raíz.
- Los datos que se leen y modifican viven en un `AsyncNotifier` (`HomeController`).
  Los que solo se leen, en un `FutureProvider` (`tipoCambioProvider`).
- La UI usa `AsyncValue.when(loading, error, data)` y diseña también el
  estado **vacío**.
- Tras escribir, el controlador **reconsulta** (`invalidateSelf`) en vez de
  modificar la lista a mano: SQLite es la única fuente de verdad.
- Los repositorios se exponen como providers para poder reemplazarlos
  (`overrideWithValue`) en las pruebas.
- Desactivamos el reintento automático de Riverpod 3 (`retry: (_, _) => null`):
  el usuario decide cuándo reintentar.

## Alternativas consideradas
- **`setState` + `FutureBuilder`**: válido para una pantalla (lo usamos en el Lab 3),
  pero el estado no se comparte y las pruebas son más difíciles.
- **BLoC**: más ceremonia (eventos + estados) para el tamaño del equipo.
- **Seguir con `ProviderContainer` manual**: obliga a pasar el controlador por
  constructores y no reconstruye la UI al cambiar.

## Consecuencias
- ➕ Cada estado de la pantalla es explícito y está probado (`test/widget_test.dart`).
- ➕ Las pruebas de widget no tocan SQLite ni internet.
- ➖ Curva de aprendizaje: `watch` vs `read`, `ref.invalidate`, `.notifier`.
- ➖ Reconsultar toda la lista tras cada guardado no escala a miles de filas;
  aceptable para el MVP.
