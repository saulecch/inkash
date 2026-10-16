import 'package:inkash/features/cuentas/data/cuentas_local_data_source.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';

class CuentasRepository {
  CuentasRepository({CuentasLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? CuentasLocalDataSource();

  final CuentasLocalDataSource _localDataSource;

  Future<List<Cuenta>> obtenerConSaldo() => _localDataSource.obtenerConSaldo();

  Future<void> guardar({
    int? id,
    required String nombre,
    required String icono,
    required int saldoInicialCentavos,
  }) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw const CuentaException('El nombre no puede quedar vacío.');
    }
    return _localDataSource.guardar(
      id: id,
      nombre: limpio,
      icono: icono,
      saldoInicialCentavos: saldoInicialCentavos,
    );
  }

  Future<void> eliminar(int id) => _localDataSource.eliminar(id);
}
