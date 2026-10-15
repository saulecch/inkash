import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';

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
class ResumenHome {
  const ResumenHome({
    required this.movimientos,
    required this.limiteMensualCentavos,
  });

  final List<Movimiento> movimientos;
  final int limiteMensualCentavos;

  // Total gastado: suma de los movimientos que son gasto.
  int get totalGastadoCentavos => movimientos
      .where((m) => !m.esIngreso)
      .fold(0, (total, m) => total + m.montoCentavos);

  // El saldo se deriva del límite y del total calculado.
  int get saldoDisponibleCentavos =>
      limiteMensualCentavos - totalGastadoCentavos;
}

class HomeController extends AsyncNotifier<ResumenHome> {
  MovimientosRepository get _repository =>
      ref.read(movimientosRepositoryProvider);

  // build() corre la primera vez que alguien hace ref.watch y cada vez que
  // se invalida. Mientras el Future no termina, el estado es AsyncLoading.
  @override
  Future<ResumenHome> build() async {
    final movimientos = await _repository.obtenerMovimientos();
    return ResumenHome(
      movimientos: movimientos,
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
    await future;
  }
}
