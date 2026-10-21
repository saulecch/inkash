import 'package:inkash/features/ajustes/data/ajustes_local_data_source.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';

class AjustesRepository {
  AjustesRepository({AjustesLocalDataSource? localDataSource})
    : _local = localDataSource ?? AjustesLocalDataSource();

  final AjustesLocalDataSource _local;

  Future<Ajustes> leer() => _local.leer();
  Future<void> guardarNombre(String nombre) =>
      _local.guardarNombre(nombre.trim());
  Future<void> guardarLimite(int centavos) => _local.guardarLimite(centavos);
  Future<void> borrarDatosDelUsuario() => _local.borrarDatosDelUsuario();
}
