import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';

// El repositorio es la frontera entre la presentación y los datos.
// Oculta la procedencia de los datos (hoy SQLite, mañana quizá una API).
class MovimientosRepository {
  MovimientosRepository({MovimientosLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? MovimientosLocalDataSource();

  final MovimientosLocalDataSource _localDataSource;

  final int limiteMensualCentavos = 650000;

  // La presentación no sabe que existe SQLite: solo pide "guarda esto".
  Future<void> guardar(NuevoMovimiento nuevo) {
    return _localDataSource.insertar(nuevo);
  }

  // Ahora es Future: leer de disco toma tiempo y puede fallar.
  Future<List<Movimiento>> obtenerMovimientos() {
    return _localDataSource.obtenerMovimientos();
  }
}
