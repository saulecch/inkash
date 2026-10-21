import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/movimiento_eliminado.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/home/domain/totales_mes.dart';

// El repositorio también es un provider: en las pruebas se reemplaza por uno
// falso con `overrideWithValue`, sin tocar SQLite.
final movimientosRepositoryProvider = Provider<MovimientosRepository>((ref) {
  return MovimientosRepository();
});

// AsyncNotifier = estado que se obtiene con un Future.
// La pantalla recibe un AsyncValue: cargando · error · datos.
final homeControllerProvider =
    AsyncNotifierProvider<HomeController, ResumenHome>(
      HomeController.new,
      // Riverpod 3 reintenta solo los errores. Lo apagamos para que el
      // usuario vea el error y decida con el botón "Reintentar".
      retry: (_, _) => null,
    );

// Lo que el dashboard necesita, ya calculado. Inmutable.
// s15-02: los totales son DEL MES y vienen sumados de SQLite. Antes se
// sumaba la lista en Dart, que además incluía todos los meses.
class ResumenHome {
  const ResumenHome({
    required this.mes,
    required this.ultimosMovimientos,
    required this.totalesMes,
    required this.limiteMensualCentavos,
  });

  final DateTime mes;
  final List<Movimiento> ultimosMovimientos;
  final TotalesMes totalesMes;
  final int limiteMensualCentavos;

  int get totalGastadoCentavos => totalesMes.gastosCentavos;

  // El saldo se deriva del límite y del total calculado.
  int get saldoDisponibleCentavos =>
      limiteMensualCentavos - totalGastadoCentavos;
}

class HomeController extends AsyncNotifier<ResumenHome> {
  MovimientosRepository get _repository =>
      ref.read(movimientosRepositoryProvider);

  // build() corre la primera vez que alguien hace ref.watch y cada vez que
  // se invalida. Mientras el Future no termina, el estado es AsyncLoading.
  static const cantidadUltimos = 5;

  @override
  Future<ResumenHome> build() async {
    final hoy = ref.read(relojProvider)();
    // Dos consultas independientes EN PARALELO: (a, b).wait espera ambas.
    // Si una falla, el build falla y la pantalla muestra el error.
    final (ultimos, totales) = await (
      _repository.obtenerMovimientos(limite: cantidadUltimos),
      _repository.totalesDelMes(hoy),
    ).wait;
    return ResumenHome(
      mes: hoy,
      ultimosMovimientos: ultimos,
      totalesMes: totales,
      limiteMensualCentavos: _repository.limiteMensualCentavos,
    );
  }

  // Si el INSERT falla, la excepción sube al formulario (que muestra el error)
  // y NO se recarga nada.
  Future<void> guardarMovimiento(NuevoMovimiento nuevo) async {
    await _repository.guardar(nuevo);
    await _refrescarTodo();
  }

  // s16-03: editar sigue la misma regla: escribir y reconsultar.
  Future<void> actualizarMovimiento(String id, NuevoMovimiento nuevo) async {
    await _repository.actualizar(id, nuevo);
    await _refrescarTodo();
  }

  // s15-04: borrar y deshacer siguen la misma regla que guardar:
  // escribir en SQLite y volver a consultar todo lo que depende de eso.
  Future<MovimientoEliminado?> eliminar(String id) async {
    final eliminado = await _repository.eliminar(id);
    await _refrescarTodo();
    return eliminado;
  }

  Future<void> deshacer(MovimientoEliminado eliminado) async {
    await _repository.restaurar(eliminado);
    await _refrescarTodo();
  }

  // Volvemos a consultar SQLite en vez de hacer lista.add(...): la base es
  // la única fuente de verdad (orden, ids y totales salen de ahí).
  // El Historial también muestra movimientos: si no lo invalidamos,
  // seguiría con la lista vieja (y quizá sin la categoría nueva).
  Future<void> _refrescarTodo() async {
    ref.invalidateSelf();
    ref.invalidate(historialProvider);
    ref.invalidate(categoriasUsadasProvider);
    ref.invalidate(cuentasProvider); // s16-01: los saldos cambian
    await future;
  }
}
