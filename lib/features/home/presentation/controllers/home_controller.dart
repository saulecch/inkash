import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:riverpod/riverpod.dart';

// Riverpod sabe cómo construir y entregar el controlador.
final movimientosControllerProvider = Provider<MovimientosController>((ref) {
  return MovimientosController();
});

class MovimientosController {
  MovimientosController({MovimientosRepository? repository})
    : _repository = repository ?? MovimientosRepository()
        {
    _movimientos = _repository.obtenerMovimientos();
  }

  final MovimientosRepository _repository;

  late final List<Movimiento> _movimientos;

  // El límite mensual proviene del repositorio.
  int get limiteMensualCentavos => _repository.limiteMensualCentavos;

  // Lista de movimientos que la pantalla puede renderizar.
  List<Movimiento> get movimientos => _movimientos;

  // El total de gastos se deriva de los movimientos mediante el repositorio.
  int get totalGastadoCentavos {
    return _repository.calcularTotalGastadoCentavos(_movimientos);
  }

  // El saldo se deriva del límite y del total calculado.
  int get saldoDisponibleCentavos {
    return limiteMensualCentavos - totalGastadoCentavos;
  }
}
