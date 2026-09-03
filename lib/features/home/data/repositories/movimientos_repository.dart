import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/movimiento.dart';

// El repositorio es la frontera entre la presentación y los datos.
// Oculta la procedencia de los datos (hoy memoria, mañana SQLite).
class MovimientosRepository {
  MovimientosRepository({MovimientosLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? MovimientosLocalDataSource();

  final MovimientosLocalDataSource _localDataSource;

  final int limiteMensualCentavos = 650000;

  List<Movimiento> obtenerMovimientos() {
    return _localDataSource.obtenerMovimientos();
  }

  // Total gastado: suma de los movimientos que son gasto (negativos).
  int calcularTotalGastadoCentavos(List<Movimiento> movimientos) {
    return movimientos
        .where((m) => !m.esIngreso)
        .fold(0, (total, m) => total + m.montoCentavos);
  }
}
