import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/metas/domain/meta.dart';

class MetasLocalDataSource {
  MetasLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // Las activas primero; las completadas al final.
  Future<List<Meta>> obtenerTodas() async {
    final db = await _database.database;
    final filas = await db.rawQuery('''
      SELECT * FROM metas
      ORDER BY ahorrado_centavos >= objetivo_centavos, creada_ms
    ''');
    return [
      for (final f in filas)
        Meta(
          id: f['id']! as int,
          nombre: f['nombre']! as String,
          objetivoCentavos: f['objetivo_centavos']! as int,
          ahorradoCentavos: f['ahorrado_centavos']! as int,
        ),
    ];
  }

  Future<void> crear(String nombre, int objetivoCentavos) async {
    final db = await _database.database;
    await db.insert('metas', {
      'nombre': nombre,
      'objetivo_centavos': objetivoCentavos,
      'creada_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // s16-05: editar nombre y objetivo (lo ahorrado no se toca aquí).
  Future<void> editar(int id, String nombre, int objetivoCentavos) async {
    final db = await _database.database;
    await db.update(
      'metas',
      {'nombre': nombre, 'objetivo_centavos': objetivoCentavos},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.delete('metas', where: 'id = ?', whereArgs: [id]);
  }

  // Positivo = aportar, negativo = retirar.
  //
  // La suma la hace SQLite en UN solo UPDATE. La versión "leer, sumar en Dart
  // y escribir" pierde aportes si dos llegan a la vez (dos pantallas, doble
  // toque): ambos leen 100, ambos escriben 150 en vez de 200.
  //
  // El WHERE también valida: si el retiro dejaría la meta en negativo, no
  // actualiza ninguna fila (rowsAffected = 0) y lo traducimos a un mensaje.
  // El CHECK de la tabla queda como última defensa.
  Future<void> mover(int metaId, int centavos) async {
    final db = await _database.database;
    final filas = await db.rawUpdate(
      '''
      UPDATE metas SET ahorrado_centavos = ahorrado_centavos + ?
      WHERE id = ? AND ahorrado_centavos + ? >= 0
      ''',
      [centavos, metaId, centavos],
    );
    if (filas == 0) {
      throw const MetaException('No puedes retirar más de lo ahorrado.');
    }
  }
}
