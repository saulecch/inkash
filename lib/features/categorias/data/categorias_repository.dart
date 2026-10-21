import 'package:inkash/features/categorias/data/categorias_local_data_source.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';

class CategoriasRepository {
  CategoriasRepository({CategoriasLocalDataSource? localDataSource})
    : _local = localDataSource ?? CategoriasLocalDataSource();

  final CategoriasLocalDataSource _local;

  Future<List<Categoria>> obtenerTodas() => _local.obtenerTodas();

  Future<void> guardar({
    int? id,
    required String nombre,
    required String icono,
    required TipoCategoria tipo,
  }) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw const CategoriaException('El nombre no puede quedar vacío.');
    }
    return _local.guardar(id: id, nombre: limpio, icono: icono, tipo: tipo);
  }

  Future<void> archivar(int id, {required bool archivada}) =>
      _local.archivar(id, archivada: archivada);

  Future<void> eliminar(int id) => _local.eliminar(id);
}
