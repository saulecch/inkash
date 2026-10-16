import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
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
    // Volvemos a consultar SQLite en vez de hacer lista.add(...): la base es
    // la única fuente de verdad (orden, ids y totales salen de ahí).
    ref.invalidateSelf();
    // s15-03: el Historial también muestra movimientos. Si no lo invalidamos,
    // seguiría con la lista vieja (y quizá sin la categoría nueva).
    ref.invalidate(historialProvider);
    ref.invalidate(categoriasUsadasProvider);
    await future;
  }
}
