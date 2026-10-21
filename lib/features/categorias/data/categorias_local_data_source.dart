import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:sqflite/sqflite.dart';

class CategoriasLocalDataSource {
  CategoriasLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Categoria>> obtenerTodas() async {
    final db = await _database.database;
    final filas = await db.query(
      'categorias',
      orderBy: 'archivada, tipo, nombre',
    );
    return [
      for (final f in filas)
        Categoria(
          id: f['id']! as int,
          nombre: f['nombre']! as String,
          icono: f['icono']! as String,
          // El texto de SQLite -> enum de Dart. byName falla si llega algo
          // que no conocemos (el CHECK de la tabla lo impide).
          tipo: TipoCategoria.values.byName(f['tipo']! as String),
          archivada: f['archivada'] == 1,
        ),
    ];
  }

  Future<void> guardar({
    int? id,
    required String nombre,
    required String icono,
    required TipoCategoria tipo,
  }) async {
    final db = await _database.database;
    final fila = {'nombre': nombre, 'icono': icono, 'tipo': tipo.name};
    try {
      if (id == null) {
        await db.insert('categorias', fila);
      } else {
        await db.update('categorias', fila, where: 'id = ?', whereArgs: [id]);
      }
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw CategoriaException('Ya existe la categoría "$nombre".');
      }
      rethrow;
    }
  }

  Future<void> archivar(int id, {required bool archivada}) async {
    final db = await _database.database;
    await db.update(
      'categorias',
      {'archivada': archivada ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Solo se borra si nunca se usó; si tiene movimientos, se sugiere archivar.
  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final usados = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM movimientos WHERE categoria_id = ?',
          [id],
        ),
      );
      if (usados! > 0) {
        throw CategoriaException(
          'Tiene $usados movimientos. Archívala para dejar de verla.',
        );
      }
      await txn.delete('categorias', where: 'id = ?', whereArgs: [id]);
    });
  }
}
