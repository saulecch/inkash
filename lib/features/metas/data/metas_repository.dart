import 'package:inkash/features/metas/data/metas_local_data_source.dart';
import 'package:inkash/features/metas/domain/meta.dart';

class MetasRepository {
  MetasRepository({MetasLocalDataSource? localDataSource})
    : _local = localDataSource ?? MetasLocalDataSource();

  final MetasLocalDataSource _local;

  Future<List<Meta>> obtenerTodas() => _local.obtenerTodas();

  Future<void> crear(String nombre, int objetivoCentavos) =>
      _local.crear(nombre.trim(), objetivoCentavos);

  Future<void> editar(int id, String nombre, int objetivoCentavos) =>
      _local.editar(id, nombre.trim(), objetivoCentavos);

  Future<void> eliminar(int id) => _local.eliminar(id);

  Future<void> aportar(int metaId, int centavos) =>
      _local.mover(metaId, centavos);

  Future<void> retirar(int metaId, int centavos) =>
      _local.mover(metaId, -centavos);
}
