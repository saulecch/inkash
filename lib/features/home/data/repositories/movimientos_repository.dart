import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/movimiento_eliminado.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/home/domain/totales_mes.dart';

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
  Future<List<Movimiento>> obtenerMovimientos({
    int? limite,
    DateTime? mes,
    String? categoria,
  }) {
    return _localDataSource.obtenerMovimientos(
      limite: limite,
      mes: mes,
      categoria: categoria,
    );
  }

  Future<MovimientoEliminado?> eliminar(String id) {
    return _localDataSource.eliminar(id);
  }

  Future<void> restaurar(MovimientoEliminado eliminado) {
    return _localDataSource.restaurar(eliminado);
  }

  Future<List<String>> obtenerCategoriasUsadas() {
    return _localDataSource.obtenerCategoriasUsadas();
  }

  Future<TotalesMes> totalesDelMes(DateTime mes) {
    return _localDataSource.totalesDelMes(mes);
  }
}
